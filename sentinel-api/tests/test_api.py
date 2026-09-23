"""
Cyber Constellation - Sentinel API Test Suite
Run: pytest tests/ -v
"""
import asyncio
import os
import sys
from unittest.mock import AsyncMock, MagicMock, patch

from httpx import ASGITransport, AsyncClient
import jwt
import pytest
import pytest_asyncio

sys.path.insert(0, "..")


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def test_app():
    os.environ.setdefault("JWT_SECRET", "test-secret-supersafe-32-chars-min")
    os.environ.setdefault("ENVIRONMENT", "test")
    os.environ.setdefault("DATABASE_URL", "postgresql://constellation:testpassword123@localhost/constellation_test")
    os.environ.setdefault("WEBHOOK_HMAC_SECRET", "test-webhook-secret")
    os.environ.setdefault("AUTH_RATE_LIMIT_RPM", "5")

    import main as app_module

    mock_pool = MagicMock()
    mock_conn = AsyncMock()
    acquire_ctx = AsyncMock()
    acquire_ctx.__aenter__.return_value = mock_conn
    acquire_ctx.__aexit__.return_value = None
    mock_pool.acquire.return_value = acquire_ctx
    app_module.pool = mock_pool
    app_module._rate_store.clear()

    return app_module.app, mock_conn, app_module


@pytest.fixture(autouse=True)
def clear_rate_limits():
    import main

    main._rate_store.clear()


@pytest.fixture
def valid_token():
    import main

    return main.create_token("user-123", "tenant-abc", "analyst")


@pytest.fixture
def superadmin_token():
    import main

    return main.create_token("super-001", "system", "superadmin")


@pytest.mark.asyncio
async def test_health_check(test_app):
    app, mock_conn, _ = test_app
    mock_conn.fetchval = AsyncMock(return_value=1)
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["ok"] is True
    assert data["version"] == "2.0.0"


@pytest.mark.asyncio
async def test_auth_required_on_protected_endpoints(test_app):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        stats = await client.get("/api/v1/dashboard/stats")
        alerts = await client.get("/api/v1/alerts/live")
        feedback = await client.post("/api/v1/feedback", json={"alert_id": "BT-1"})
    assert stats.status_code == 401
    assert alerts.status_code == 401
    assert feedback.status_code == 401


@pytest.mark.asyncio
async def test_jwt_auth_works(test_app, valid_token):
    app, mock_conn, _ = test_app
    mock_conn.fetchval = AsyncMock(return_value=5)
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/api/v1/dashboard/stats",
            headers={"Authorization": f"Bearer {valid_token}"},
        )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_expired_token_rejected(test_app):
    app, _, app_module = test_app
    expired = jwt.encode(
        {
            "sub": "u1",
            "tenant_id": "t1",
            "role": "analyst",
            "exp": app_module.utcnow() - app_module.timedelta(hours=1),
        },
        app_module.JWT_SECRET,
        algorithm=app_module.JWT_ALGORITHM,
    )
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/api/v1/dashboard/stats",
            headers={"Authorization": f"Bearer {expired}"},
        )
    assert response.status_code == 401
    assert "expired" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_invalid_token_rejected(test_app):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/api/v1/dashboard/stats",
            headers={"Authorization": "Bearer garbage.token.here"},
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_rate_limit_on_auth_endpoint(test_app):
    app, mock_conn, _ = test_app
    mock_conn.fetchrow = AsyncMock(return_value=None)
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        responses = []
        for _ in range(8):
            response = await client.post("/auth/token", json={"username": "x", "password": "y"})
            responses.append(response.status_code)
    assert 429 in responses


@pytest.mark.asyncio
async def test_dashboard_stats_returns_tenant_data(test_app, valid_token):
    app, mock_conn, _ = test_app
    mock_conn.fetchval = AsyncMock(return_value=42)
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/api/v1/dashboard/stats",
            headers={"Authorization": f"Bearer {valid_token}"},
        )
    assert response.status_code == 200
    data = response.json()
    assert data["tenant_id"] == "tenant-abc"
    assert "alerts_24h" in data
    assert "automation_rate" in data
    assert "generated_at" in data


@pytest.mark.asyncio
async def test_feedback_valid_submission(test_app, valid_token):
    app, mock_conn, _ = test_app
    mock_conn.execute = AsyncMock()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/feedback",
            headers={"Authorization": f"Bearer {valid_token}"},
            json={"alert_id": "BT-123", "rule_id": "5503", "verdict": "true_positive", "confidence_at_time": 87},
        )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "recorded"
    assert data["verdict"] == "true_positive"


@pytest.mark.asyncio
async def test_feedback_invalid_verdict(test_app, valid_token):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/feedback",
            headers={"Authorization": f"Bearer {valid_token}"},
            json={"alert_id": "BT-123", "rule_id": "5503", "verdict": "maybe"},
        )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_feedback_missing_required_fields(test_app, valid_token):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/feedback",
            headers={"Authorization": f"Bearer {valid_token}"},
            json={"alert_id": "BT-123"},
        )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_webhook_requires_hmac(test_app):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/webhook/event", json={"tenant_id": "t1", "event": "test"})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_webhook_with_valid_hmac(test_app):
    app, _, app_module = test_app
    payload = b'{"tenant_id":"default","event":"test_event"}'
    signature = "sha256=" + app_module.hmac.new(
        app_module.WEBHOOK_SECRET.encode(),
        payload,
        app_module.hashlib.sha256,
    ).hexdigest()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        with patch("aiohttp.ClientSession") as mock_session:
            mock_resp = AsyncMock()
            mock_resp.json = AsyncMock(return_value={"event_id": "test-123"})
            mock_session.return_value.__aenter__ = AsyncMock(return_value=mock_session.return_value)
            mock_session.return_value.__aexit__ = AsyncMock(return_value=None)
            mock_session.return_value.post.return_value.__aenter__ = AsyncMock(return_value=mock_resp)
            mock_session.return_value.post.return_value.__aexit__ = AsyncMock(return_value=None)
            response = await client.post(
                "/api/v1/webhook/event",
                content=payload,
                headers={"X-Constellation-Signature": signature, "Content-Type": "application/json"},
            )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_admin_endpoint_blocks_analyst(test_app, valid_token):
    app, _, _ = test_app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/admin/tenants",
            headers={"Authorization": f"Bearer {valid_token}"},
            json={"tenant_name": "Acme", "admin_email": "admin@acme.com", "plan": "starter"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_endpoint_allows_superadmin(test_app, superadmin_token):
    app, mock_conn, _ = test_app
    mock_conn.execute = AsyncMock()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/admin/tenants",
            headers={"Authorization": f"Bearer {superadmin_token}"},
            json={"tenant_name": "Acme Corp", "admin_email": "admin@acme.com", "plan": "professional"},
        )
    assert response.status_code == 200
    data = response.json()
    assert "tenant_id" in data
    assert "webhook_secret" in data
    assert data["plan"] == "professional"


def test_verify_webhook_signature_correct():
    import main

    body = b'{"test":"payload"}'
    signature = "sha256=" + main.hmac.new(main.WEBHOOK_SECRET.encode(), body, main.hashlib.sha256).hexdigest()
    assert main.verify_webhook_signature(body, signature) is True


def test_verify_webhook_signature_tampered():
    import main

    assert main.verify_webhook_signature(b'{"test":"payload"}', "sha256=deadbeef") is False


def test_verify_webhook_signature_missing():
    import main

    assert main.verify_webhook_signature(b"data", "") is False


def test_create_token_structure():
    import main

    token = main.create_token("user-1", "tenant-1", "analyst")
    payload = jwt.decode(token, main.JWT_SECRET, algorithms=[main.JWT_ALGORITHM])
    assert payload["sub"] == "user-1"
    assert payload["tenant_id"] == "tenant-1"
    assert payload["role"] == "analyst"
    assert payload["iss"] == "constellation-sentinel"
    assert payload["jti"]


def test_create_token_is_unique():
    import main

    token_one = main.create_token("u1", "t1", "analyst")
    token_two = main.create_token("u1", "t1", "analyst")
    assert token_one != token_two
