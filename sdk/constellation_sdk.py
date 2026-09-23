"""
Cyber Constellation Python SDK
pip install constellation-sdk

Usage:
    from constellation import ConstellationClient
    client = ConstellationClient(base_url="https://your-instance.com", api_key="your-key")
    stats = client.dashboard.stats()
    client.feedback.submit(alert_id="BT-123", rule_id="5503", verdict="true_positive")
"""
import requests, time, json
from typing import Optional, List, Dict, Any
from datetime import datetime
from dataclasses import dataclass, asdict

__version__ = "1.0.0"
__all__ = ["ConstellationClient", "ConstellationError", "AuthError", "RateLimitError"]


# ─── Exceptions ───────────────────────────────────────────────────────────────
class ConstellationError(Exception):
    def __init__(self, message: str, status_code: int = None, response: dict = None):
        self.message = message
        self.status_code = status_code
        self.response = response or {}
        super().__init__(message)

class AuthError(ConstellationError): pass
class RateLimitError(ConstellationError):
    def __init__(self, retry_after: int = 60):
        self.retry_after = retry_after
        super().__init__(f"Rate limit exceeded. Retry after {retry_after}s", 429)

class NotFoundError(ConstellationError): pass


# ─── Data Models ──────────────────────────────────────────────────────────────
@dataclass
class Alert:
    event_id: str
    severity: str
    rule_id: str
    src_ip: Optional[str]
    username: Optional[str]
    agent_name: Optional[str]
    confidence_score: int
    triage_decision: Optional[str]
    kill_chain_stage: Optional[str]
    ai_urgency: Optional[str]
    ai_verdict_hint: Optional[str]
    processed_at: str

    @classmethod
    def from_dict(cls, d: dict) -> "Alert":
        return cls(**{k: d.get(k) for k in cls.__dataclass_fields__})

@dataclass
class DashboardStats:
    tenant_id: str
    alerts_24h: int
    incidents_24h: int
    auto_resolved_24h: int
    automation_rate: float
    sla_breaches: int
    feedback_30d: int
    errors_24h: int
    generated_at: str


# ─── HTTP Layer ───────────────────────────────────────────────────────────────
class _HTTPClient:
    def __init__(self, base_url: str, token: str, timeout: int = 30, max_retries: int = 3):
        self._base = base_url.rstrip("/")
        self._token = token
        self._timeout = timeout
        self._max_retries = max_retries
        self._session = requests.Session()
        self._session.headers.update({
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": f"constellation-sdk-python/{__version__}",
        })

    def request(self, method: str, path: str, **kwargs) -> dict:
        url = f"{self._base}{path}"
        last_err = None

        for attempt in range(self._max_retries):
            try:
                resp = self._session.request(method, url, timeout=self._timeout, **kwargs)
            except requests.ConnectionError as e:
                last_err = ConstellationError(f"Connection error: {e}")
                time.sleep(2 ** attempt)
                continue

            if resp.status_code == 200:
                return resp.json()
            elif resp.status_code == 401:
                raise AuthError("Authentication failed — check your API key", 401)
            elif resp.status_code == 403:
                raise ConstellationError("Insufficient permissions", 403)
            elif resp.status_code == 404:
                raise NotFoundError(f"Not found: {path}", 404)
            elif resp.status_code == 422:
                raise ConstellationError(f"Validation error: {resp.text}", 422)
            elif resp.status_code == 429:
                retry_after = int(resp.headers.get("Retry-After", 60))
                if attempt < self._max_retries - 1:
                    time.sleep(retry_after)
                    continue
                raise RateLimitError(retry_after)
            elif resp.status_code >= 500:
                last_err = ConstellationError(f"Server error {resp.status_code}", resp.status_code)
                time.sleep(2 ** attempt)
                continue
            else:
                raise ConstellationError(f"HTTP {resp.status_code}: {resp.text}", resp.status_code)

        raise last_err or ConstellationError("Max retries exceeded")

    def get(self, path: str, params: dict = None) -> dict:
        return self.request("GET", path, params=params)

    def post(self, path: str, data: dict = None) -> dict:
        return self.request("POST", path, json=data)


# ─── Resource Classes ──────────────────────────────────────────────────────────
class DashboardResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def stats(self) -> DashboardStats:
        """Get 24-hour SOC dashboard statistics."""
        data = self._http.get("/api/v1/dashboard/stats")
        return DashboardStats(**{k: data.get(k) for k in DashboardStats.__dataclass_fields__})


class AlertsResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def list(self, limit: int = 20, severity: str = None) -> List[Alert]:
        """Get recent alerts with optional severity filter."""
        params = {"limit": limit}
        if severity:
            params["severity"] = severity
        data = self._http.get("/api/v1/alerts/live", params=params)
        return [Alert.from_dict(a) for a in data]

    def critical(self, limit: int = 10) -> List[Alert]:
        """Shortcut: get critical alerts only."""
        return self.list(limit=limit, severity="critical")


class CorrelationsResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def active(self) -> List[Dict]:
        """Get active correlated incidents."""
        return self._http.get("/api/v1/correlations/active")


class VulnerabilitiesResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def queue(self, limit: int = 25) -> List[Dict]:
        """Get vulnerability risk queue ordered by composite score."""
        return self._http.get("/api/v1/vulnerabilities/queue", params={"limit": limit})

    def sla_breaches(self) -> List[Dict]:
        """Get vulnerabilities past SLA."""
        return [v for v in self.queue(limit=100) if v.get("sla_breached")]


class FeedbackResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def submit(self, alert_id: str, rule_id: str, verdict: str,
               workflow_name: str = None, confidence_at_time: int = None,
               notes: str = None) -> Dict:
        """Submit analyst verdict. verdict must be: true_positive|false_positive|noise|needs_tuning"""
        valid_verdicts = {"true_positive", "false_positive", "noise", "needs_tuning"}
        if verdict not in valid_verdicts:
            raise ValueError(f"verdict must be one of {valid_verdicts}")
        payload = {
            "alert_id": alert_id,
            "rule_id": rule_id,
            "verdict": verdict,
        }
        if workflow_name: payload["workflow_name"] = workflow_name
        if confidence_at_time is not None: payload["confidence_at_time"] = confidence_at_time
        if notes: payload["notes"] = notes
        return self._http.post("/api/v1/feedback", payload)

    def true_positive(self, alert_id: str, rule_id: str, **kwargs) -> Dict:
        return self.submit(alert_id, rule_id, "true_positive", **kwargs)

    def false_positive(self, alert_id: str, rule_id: str, **kwargs) -> Dict:
        return self.submit(alert_id, rule_id, "false_positive", **kwargs)


class TuningResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def rules(self) -> List[Dict]:
        """Get self-tuning rule health status."""
        return self._http.get("/api/v1/tuning/rules")

    def high_fp_rules(self, threshold: float = 15.0) -> List[Dict]:
        """Rules with FP rate above threshold (default 15%)."""
        return [r for r in self.rules() if float(r.get("fp_rate", 0)) >= threshold]


class AgentsResource:
    def __init__(self, http: _HTTPClient):
        self._http = http

    def health(self) -> List[Dict]:
        """Get agent fleet health — workflows with errors in past 24h."""
        return self._http.get("/api/v1/agents/health")

    def unhealthy(self) -> List[Dict]:
        """Agents with dead-letter events."""
        return [a for a in self.health() if a.get("dead_letters", 0) > 0]


# ─── Main Client ───────────────────────────────────────────────────────────────
class ConstellationClient:
    """
    Cyber Constellation API Client

    Args:
        base_url: Base URL of your Constellation instance
        api_key:  JWT token OR username/password for auto-login
        username: Username (if not using api_key)
        password: Password (if not using api_key)
        timeout:  Request timeout in seconds (default: 30)

    Example:
        # With API key
        client = ConstellationClient("https://soc.yourcompany.com", api_key="eyJ...")

        # With credentials (auto-login)
        client = ConstellationClient("https://soc.yourcompany.com",
                                     username="analyst1", password="secret")

        # Usage
        stats = client.dashboard.stats()
        print(f"Alerts today: {stats.alerts_24h}, Automation: {stats.automation_rate}%")

        alerts = client.alerts.critical()
        for alert in alerts:
            if some_validation(alert):
                client.feedback.true_positive(alert.event_id, alert.rule_id)
    """

    def __init__(self, base_url: str, api_key: str = None,
                 username: str = None, password: str = None,
                 timeout: int = 30):
        if not api_key and not (username and password):
            raise ValueError("Provide either api_key or username+password")

        if not api_key:
            api_key = self._login(base_url, username, password)

        self._http = _HTTPClient(base_url, api_key, timeout)

        # Resource namespaces
        self.dashboard      = DashboardResource(self._http)
        self.alerts         = AlertsResource(self._http)
        self.correlations   = CorrelationsResource(self._http)
        self.vulnerabilities = VulnerabilitiesResource(self._http)
        self.feedback       = FeedbackResource(self._http)
        self.tuning         = TuningResource(self._http)
        self.agents         = AgentsResource(self._http)

    def _login(self, base_url: str, username: str, password: str) -> str:
        resp = requests.post(
            f"{base_url.rstrip('/')}/auth/token",
            json={"username": username, "password": password},
            timeout=10
        )
        if resp.status_code != 200:
            raise AuthError(f"Login failed: {resp.text}", resp.status_code)
        return resp.json()["access_token"]

    def health(self) -> Dict:
        """Check if the Constellation instance is healthy."""
        return self._http.get("/health")

    def __repr__(self):
        return f"ConstellationClient(base_url={self._http._base})"
