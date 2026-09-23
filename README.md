# Cyber Constellation — Security Automation Platform

Security automation platform. 65 orchestrated workflows covering SOC operations, GRC,
identity, vulnerability management, DFIR, DevSecOps and cloud posture — with a FastAPI
control plane in front of them and a hardened container deployment underneath.

Built to answer a practical question: how much of a small security team's repetitive
work can be automated without giving up auditability?

---

## Architecture

```
                    ┌──────────────────────┐
  webhooks ────────►│  sentinel-api        │  JWT auth · HMAC verification
  (HMAC-signed)     │  FastAPI control     │  rate limiting · tenant isolation
                    │  plane               │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │  master-orchestrator │  routing · retry · dead-letter
                    └──────────┬───────────┘
                               │
     ┌───────────┬─────────────┼─────────────┬───────────┐
     ▼           ▼             ▼             ▼           ▼
  Blue Team    GRC          IAM          Vuln Mgmt    DFIR  ... 12 domains
   (6)         (5)          (5)            (6)         (5)

                    ┌──────────────────────┐
                    │  PostgreSQL  45 tables│ ◄── Grafana: SOC / Vuln / GRC
                    └──────────────────────┘
```

## What's in here

| Path | Contents |
|------|----------|
| `workflows/` | All 65 workflow definitions, grouped by domain — catalogue in [`INDEX.md`](workflows/INDEX.md) |
| `sentinel-api/` | FastAPI control plane + test suite |
| `scripts/` | Schema (45 tables, 23 indexes), multi-tenancy migration, health check, credential setup guide |
| `grafana/` | Provisioned SOC dashboard |
| `nginx/` | TLS 1.2/1.3 termination, rate limiting, HSTS and security headers |
| `deploy/` | Production Compose stack — pinned images, log rotation, scheduled backups |
| `ai-models/` | Threat-analysis system prompt and a library of threat-hunt queries |
| `sdk/` | Typed Python client for the control plane |
| `.github/workflows/` | CI: validate → test → security scan → build |

## Workflow domains

| Prefix | Domain | Count |
|--------|--------|-------|
| `CORE-` | Orchestration — event intake, routing, retry and dead-letter handling | 1 |
| `AI-` | AI layer — LLM-backed threat enrichment | 1 |
| `BT-` | Blue team — SIEM enrichment, IOC ingestion, IR playbooks, false-positive tuning, shift handover, threat hunting | 6 |
| `VM-` | Vulnerability management — scanner aggregation, Patch Tuesday, CVSS/EPSS prioritisation, zero-day war room, SLA alerting, attack-path mapping | 6 |
| `CS-` | Cloud security — misconfiguration scanning, container and IaC gates, CSPM, inventory, IAM permission audit | 6 |
| `EP-` | Endpoint — EDR enrichment, patch compliance, hash blocking, unmanaged devices, USB policy | 5 |
| `NET-` | Network — firewall audit, DNS anomaly, dark-web monitoring, VPN anomaly, baseline drift | 5 |
| `RT-` | Red team — OSINT recon, exploit triage, phishing simulation, attack surface, bug bounty | 5 |
| `IAM-` | Identity — PAM review, offboarding, MFA enforcement, impossible travel, shadow SaaS | 5 |
| `GRC-` | Governance — audit scheduling, risk register, policy tracking, vendor risk, GDPR breach pipeline | 5 |
| `DFIR-` | Forensics — evidence logging, timeline building, sandboxing, memory capture, chain of custody | 5 |
| `DS-` | DevSecOps — SAST/DAST gate, dependency SLA, code review routing, bug SLA, SBOM generation | 5 |
| `TI-` | Threat intel — daily brief, IOC processing, brand monitoring, TTP profiling, geo adaptation | 5 |
| `AWR-` | Awareness — phishing tracking, training compliance, threat digest, password alerts, leaderboard | 5 |

## Security decisions

These are the choices worth arguing about in a review, so they're stated plainly:

- **Authentication** — JWT on every `/api/v1/*` route, 8-hour expiry, RS256-ready.
- **Webhook integrity** — HMAC-SHA256 signature verification on every inbound webhook.
  An unsigned webhook endpoint is an unauthenticated RPC into your SOC.
- **Rate limiting** — 60 rpm general, 5 rpm on auth, 100 rpm on webhooks.
- **Tenant isolation** — `tenant_id` on 18 core tables; every query filters on it, and
  plan limits are enforced at the API layer rather than trusting the caller.
- **Transport** — TLS 1.3, HSTS, CSP and `X-Frame-Options` at the edge.
- **No silent failures** — every workflow sets an error workflow. Retries back off
  30s → 60s → 120s, then land in a dead-letter queue that raises a ticket.
- **Pinned images** — no `latest` anywhere in the production Compose file.

## Running it

```bash
cd deploy
cp ../.env.example .env        # fill in every value marked REQUIRED
docker compose -f docker-compose.prod.yml up -d

docker exec -i constellation-db psql -U constellation constellation < ../scripts/init_db_COMPLETE.sql
docker exec -i constellation-db psql -U constellation constellation < ../scripts/init_multitenancy.sql

../scripts/health-check.sh
```

`health-check.sh` verifies each service and every webhook endpoint before you trust the stack.

## Tests

```bash
cd sentinel-api && pytest
```

20 tests, concentrated on the authentication and webhook-signature paths — the parts
where a bug is a vulnerability rather than a defect.

## Status and honesty notes

- Built and tested in a self-owned lab environment. Not running in anyone's production.
- The three simulated organisations in the demo data are fictitious.
- Workflow definitions reference integrations that need your own credentials; nothing
  in this repository contains real keys, and `.env.example` ships placeholders only.

## Licence

MIT — see [LICENSE](LICENSE).

---

Gururaj Seethuru · Bengaluru · [gururajseethur.in](https://gururajseethur.in)
