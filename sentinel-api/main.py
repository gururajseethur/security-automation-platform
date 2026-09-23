"""
Cyber Constellation - SENTINEL API v2.0
Production-grade FastAPI backend with JWT auth, HMAC webhook verification,
rate limiting, tenant isolation, and usage metering.
"""
from contextlib import asynccontextmanager
from uuid import uuid4
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Optional
import asyncio
import asyncpg
import hashlib
import hmac
import json
import os
import time

import jwt
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

# Config
DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRE_MINS = int(os.getenv("JWT_EXPIRE_MINS", "480"))  # 8 hours
WEBHOOK_SECRET = os.getenv("WEBHOOK_HMAC_SECRET", "change-webhook-secret")
RATE_LIMIT_RPM = int(os.getenv("RATE_LIMIT_RPM", "120"))
AUTH_RATE_LIMIT_RPM = int(os.getenv("AUTH_RATE_LIMIT_RPM", "5"))
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "https://yourdomain.com").split(",")
VERSION = "2.0.0"

pool: Optional[asyncpg.Pool] = None
bearer_scheme = HTTPBearer(auto_error=False)
_rate_store: dict[str, list[float]] = defaultdict(list)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


async def rate_limit(request: Request, limit: int = RATE_LIMIT_RPM):
    client_ip = request.client.host if request.client else "unknown"
    now = time.time()
    window = 60
    _rate_store[client_ip] = [t for t in _rate_store[client_ip] if now - t < window]
    if len(_rate_store[client_ip]) >= limit:
        raise HTTPException(
            status_code=429,
            detail=f"Rate limit exceeded: {limit} requests/minute",
            headers={"Retry-After": "60"},
        )
    _rate_store[client_ip].append(now)


async def auth_rate_limit(request: Request):
    await rate_limit(request, AUTH_RATE_LIMIT_RPM)


def create_token(user_id: str, tenant_id: str, role: str) -> str:
    now = utcnow()
    payload = {
        "sub": user_id,
        "tenant_id": tenant_id,
        "role": role,
        "exp": now + timedelta(minutes=JWT_EXPIRE_MINS),
        "iat": now,
        "iss": "constellation-sentinel",
        "jti": uuid4().hex,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
):
    if not credentials:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        return jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(status_code=401, detail="Token expired") from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail="Invalid token") from exc


def verify_webhook_signature(request_body: bytes, signature_header: str) -> bool:
    """Verify HMAC-SHA256 signature from n8n or external systems."""
    if not signature_header:
        return False
    expected = hmac.new(WEBHOOK_SECRET.encode(), request_body, hashlib.sha256).hexdigest()
    received = signature_header.replace("sha256=", "")
    return hmac.compare_digest(expected, received)


@asynccontextmanager
async def lifespan(_: FastAPI):
    global pool
    if DATABASE_URL:
        pool = await asyncpg.create_pool(
            DATABASE_URL,
            min_size=3,
            max_size=20,
            command_timeout=30,
            max_inactive_connection_lifetime=300,
        )
    else:
        pool = None
    try:
        yield
    finally:
        if pool:
            await pool.close()


app = FastAPI(
    title="SENTINEL API",
    version=VERSION,
    description="Cyber Constellation Security Operations Dashboard API",
    docs_url="/docs" if ENVIRONMENT != "production" else None,
    redoc_url="/redoc" if ENVIRONMENT != "production" else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT"],
    allow_headers=["*"],
)


def require_pool() -> asyncpg.Pool:
    if pool is None:
        raise HTTPException(status_code=503, detail="Database pool is not configured")
    return pool


@app.get("/health")
async def health():
    db_ok = False
    current_pool = pool
    if current_pool:
        try:
            async with current_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            db_ok = True
        except Exception:
            db_ok = False
    return {
        "ok": db_ok,
        "version": VERSION,
        "environment": ENVIRONMENT,
        "timestamp": utcnow().isoformat(),
    }


@app.post("/auth/token")
async def login(request: Request, _=Depends(auth_rate_limit)):
    """Issue JWT token. In production wire to your SSO/LDAP."""
    body = await request.json()
    username = body.get("username", "")
    password = body.get("password", "")

    async with require_pool().acquire() as conn:
        user = await conn.fetchrow(
            "SELECT user_id, tenant_id, role, password_hash FROM sentinel_users WHERE username=$1 AND active=true",
            username,
        )

    if not user:
        await asyncio.sleep(0.5)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    password_hash = hashlib.sha256(password.encode()).hexdigest()
    if password_hash != user["password_hash"]:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_token(str(user["user_id"]), str(user["tenant_id"]), user["role"])
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": JWT_EXPIRE_MINS * 60,
    }


@app.get("/api/v1/dashboard/stats")
async def dashboard_stats(user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    async with require_pool().acquire() as conn:
        alerts = await conn.fetchval(
            "SELECT COUNT(*) FROM bt_alert_log WHERE processed_at >= NOW() - INTERVAL '24 hours' AND tenant_id=$1",
            tenant_id,
        )
        incidents = await conn.fetchval(
            "SELECT COUNT(*) FROM correlated_incidents WHERE created_at >= NOW() - INTERVAL '24 hours' AND tenant_id=$1",
            tenant_id,
        )
        auto_res = await conn.fetchval(
            "SELECT COUNT(*) FROM bt_alert_log WHERE triage_decision LIKE 'AUTO%' AND processed_at >= NOW() - INTERVAL '24 hours' AND tenant_id=$1",
            tenant_id,
        )
        sla_b = await conn.fetchval(
            "SELECT COUNT(*) FROM vulnerabilities WHERE sla_breached=true AND status='open' AND tenant_id=$1",
            tenant_id,
        )
        fb_count = await conn.fetchval(
            "SELECT COUNT(*) FROM analyst_feedback WHERE submitted_at >= NOW() - INTERVAL '30 days' AND tenant_id=$1",
            tenant_id,
        )
        err_count = await conn.fetchval(
            "SELECT COUNT(*) FROM constellation_errors WHERE timestamp >= NOW() - INTERVAL '24 hours' AND tenant_id=$1",
            tenant_id,
        )
    return {
        "tenant_id": tenant_id,
        "alerts_24h": alerts,
        "incidents_24h": incidents,
        "auto_resolved_24h": auto_res,
        "automation_rate": round(auto_res / max(alerts, 1) * 100, 1) if alerts else 0,
        "sla_breaches": sla_b,
        "feedback_30d": fb_count,
        "errors_24h": err_count,
        "generated_at": utcnow().isoformat(),
    }


@app.get("/api/v1/alerts/live")
async def live_alerts(
    limit: int = 20,
    severity: Optional[str] = None,
    user=Depends(get_current_user),
    _=Depends(rate_limit),
):
    tenant_id = user.get("tenant_id")
    where = "WHERE tenant_id=$1"
    params = [tenant_id]
    if severity:
        where += " AND severity=$2"
        params.append(severity)
    async with require_pool().acquire() as conn:
        rows = await conn.fetch(
            f"""
            SELECT event_id, severity, rule_id, src_ip, username, agent_name,
                   confidence_score, triage_decision, geo_country, vt_score,
                   kill_chain_stage, ai_urgency, ai_verdict_hint, ai_narrative, processed_at
            FROM bt_alert_log {where}
            ORDER BY processed_at DESC LIMIT {limit}
        """,
            *params,
        )
    return [dict(row) for row in rows]


@app.get("/api/v1/correlations/active")
async def active_correlations(user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    async with require_pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT correlation_id, type, pivot, severity, alert_count,
                   narrative, mitre_hypothesis, recommended_action,
                   first_seen, last_seen, jira_key, resolution, created_at
            FROM correlated_incidents
            WHERE tenant_id=$1 AND created_at >= NOW() - INTERVAL '24 hours'
            ORDER BY CASE severity WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 ELSE 3 END, alert_count DESC
        """,
            tenant_id,
        )
    return [dict(row) for row in rows]


@app.get("/api/v1/vulnerabilities/queue")
async def vuln_queue(limit: int = 25, user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    async with require_pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT cve_id, cvss_v3, epss_score, composite_score, priority_tier,
                   sla_breached, days_open, asset_id, asset_criticality, assigned_to
            FROM vulnerabilities
            WHERE tenant_id=$1 AND status='open' AND cvss_score >= 7.0
            ORDER BY composite_score DESC LIMIT $2
        """,
            tenant_id,
            limit,
        )
    return [dict(row) for row in rows]


@app.get("/api/v1/agents/health")
async def agent_health(user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    async with require_pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT workflow_name,
                   COUNT(*) as errors_24h,
                   SUM(CASE WHEN should_retry=false AND severity='critical' THEN 1 ELSE 0 END) as dead_letters,
                   MAX(timestamp) as last_error
            FROM constellation_errors
            WHERE tenant_id=$1 AND timestamp >= NOW() - INTERVAL '24 hours'
            GROUP BY workflow_name
        """,
            tenant_id,
        )
    return [dict(row) for row in rows]


@app.get("/api/v1/tuning/rules")
async def tuning_rules(user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    async with require_pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT f.rule_id,
                   COUNT(*) as total_verdicts,
                   ROUND(100.0*SUM(CASE WHEN f.verdict IN ('false_positive','noise') THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),1) as fp_rate,
                   COALESCE(t.confidence_threshold, 75) as threshold,
                   COALESCE(t.recommendation, 'no_change') as recommendation,
                   t.updated_at as last_tuned
            FROM analyst_feedback f
            LEFT JOIN rule_thresholds t ON f.rule_id=t.rule_id
            WHERE f.tenant_id=$1 AND f.submitted_at >= NOW() - INTERVAL '30 days'
            GROUP BY f.rule_id, t.confidence_threshold, t.recommendation, t.updated_at
            ORDER BY fp_rate DESC
        """,
            tenant_id,
        )
    return [dict(row) for row in rows]


@app.post("/api/v1/feedback")
async def submit_feedback(request: Request, user=Depends(get_current_user), _=Depends(rate_limit)):
    tenant_id = user.get("tenant_id")
    analyst = user.get("sub")
    payload = await request.json()

    for required in ["alert_id", "rule_id", "verdict"]:
        if required not in payload:
            raise HTTPException(status_code=422, detail=f"Missing: {required}")

    if payload["verdict"] not in ["true_positive", "false_positive", "noise", "needs_tuning"]:
        raise HTTPException(status_code=422, detail="Invalid verdict value")

    async with require_pool().acquire() as conn:
        await conn.execute(
            """
            INSERT INTO analyst_feedback
              (feedback_id, submitted_at, alert_id, rule_id, workflow_name, analyst, verdict, confidence_at_time, notes, tenant_id)
            VALUES ($1, NOW(), $2, $3, $4, $5, $6, $7, $8, $9)
        """,
            f"FB-{int(time.time() * 1000)}",
            payload["alert_id"],
            payload["rule_id"],
            payload.get("workflow_name"),
            analyst,
            payload["verdict"],
            payload.get("confidence_at_time", 0),
            payload.get("notes", ""),
            tenant_id,
        )

    return {"status": "recorded", "analyst": analyst, "verdict": payload["verdict"]}


@app.post("/api/v1/webhook/event")
async def receive_event(request: Request, _=Depends(rate_limit)):
    """Authenticated webhook endpoint for n8n -> Sentinel API event forwarding."""
    body = await request.body()
    signature = request.headers.get("X-Constellation-Signature", "")

    if not verify_webhook_signature(body, signature):
        raise HTTPException(status_code=401, detail="Invalid webhook signature")

    data = json.loads(body)
    tenant_id = data.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=422, detail="tenant_id required in payload")

    import aiohttp

    n8n_url = os.getenv("N8N_INTERNAL_URL", "http://n8n:5678")
    async with aiohttp.ClientSession() as session:
        async with session.post(
            f"{n8n_url}/webhook/constellation/event",
            json=data,
            headers={"X-Constellation-Tenant": tenant_id},
            timeout=aiohttp.ClientTimeout(total=10),
        ) as response:
            result = await response.json()

    return {"status": "forwarded", "event_id": result.get("event_id")}


@app.post("/api/v1/admin/tenants")
async def provision_tenant(request: Request, user=Depends(get_current_user), _=Depends(rate_limit)):
    if user.get("role") != "superadmin":
        raise HTTPException(status_code=403, detail="Superadmin required")

    body = await request.json()
    for required in ["tenant_name", "admin_email", "plan"]:
        if required not in body:
            raise HTTPException(status_code=422, detail=f"Missing: {required}")

    if body["plan"] not in ["starter", "professional", "enterprise"]:
        raise HTTPException(status_code=422, detail="Plan must be starter/professional/enterprise")

    import secrets

    tenant_id = secrets.token_hex(8)
    webhook_key = secrets.token_hex(32)

    async with require_pool().acquire() as conn:
        await conn.execute(
            """
            INSERT INTO tenants (tenant_id, tenant_name, admin_email, plan, webhook_secret, created_at)
            VALUES ($1, $2, $3, $4, $5, NOW())
        """,
            tenant_id,
            body["tenant_name"],
            body["admin_email"],
            body["plan"],
            webhook_key,
        )

    return {
        "tenant_id": tenant_id,
        "tenant_name": body["tenant_name"],
        "plan": body["plan"],
        "webhook_secret": webhook_key,
        "n8n_webhook_url": f"{os.getenv('N8N_PUBLIC_URL', 'https://yourdomain.com')}/webhook/constellation/event",
        "message": "Configure WEBHOOK_HMAC_SECRET in your n8n instance with the webhook_secret value",
    }


@app.get("/api/v1/admin/usage/{tenant_id}")
async def get_usage(tenant_id: str, user=Depends(get_current_user), _=Depends(rate_limit)):
    if user.get("role") not in ["superadmin", "billing"] and user.get("tenant_id") != tenant_id:
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    async with require_pool().acquire() as conn:
        usage = await conn.fetchrow(
            """
            SELECT
                COUNT(*) as total_events,
                SUM(CASE WHEN created_at >= date_trunc('month', NOW()) THEN 1 ELSE 0 END) as events_this_month,
                SUM(CASE WHEN created_at >= date_trunc('month', NOW()) AND source='ai_enrichment' THEN 1 ELSE 0 END) as ai_calls_this_month,
                COUNT(DISTINCT DATE(created_at)) as active_days_this_month
            FROM constellation_events WHERE tenant_id=$1
        """,
            tenant_id,
        )

        limit = await conn.fetchrow(
            "SELECT event_limit, ai_call_limit FROM tenant_plans WHERE tenant_id=$1",
            tenant_id,
        )

    return {
        "tenant_id": tenant_id,
        "period": utcnow().strftime("%Y-%m"),
        "events_this_month": usage["events_this_month"],
        "ai_calls_this_month": usage["ai_calls_this_month"],
        "event_limit": limit["event_limit"] if limit else None,
        "ai_call_limit": limit["ai_call_limit"] if limit else None,
        "generated_at": utcnow().isoformat(),
    }
