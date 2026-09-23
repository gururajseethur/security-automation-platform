#!/bin/bash
# Cyber Constellation — Agent Health Check
# Usage: ./health-check.sh [--verbose]

CYAN='\033[0;36m'; GREEN='\033[0;32m'; AMBER='\033[0;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_PASS="${N8N_BASIC_AUTH_PASSWORD:-}"
VERBOSE="${1:-}"

ok() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${AMBER}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; FAILED=$((FAILED+1)); }

FAILED=0
echo -e "${CYAN}${BOLD}⬡ Cyber Constellation Health Check${NC}"
echo -e "${CYAN}$(date)${NC}\n"

# ── Service Health ───────────────────────────────────────────────────────────
echo -e "${BOLD}── Services ──────────────────────────────────────────${NC}"

# n8n
if curl -sf --max-time 5 "$N8N_URL/healthz" | grep -q "ok"; then
  ok "n8n: $N8N_URL"
else
  fail "n8n: $N8N_URL unreachable"
fi

# Sentinel API
if curl -sf --max-time 5 "http://localhost:8000/health" | grep -q "ok"; then
  ok "Sentinel API: http://localhost:8000"
else
  warn "Sentinel API: http://localhost:8000 not responding"
fi

# Grafana
if curl -sf --max-time 5 "http://localhost:3000/api/health" | grep -q "ok"; then
  ok "Grafana: http://localhost:3000"
else
  warn "Grafana: http://localhost:3000 not responding"
fi

# PostgreSQL
if docker exec constellation-db pg_isready -U constellation >/dev/null 2>&1; then
  ok "PostgreSQL: constellation-db"
else
  fail "PostgreSQL: constellation-db not ready"
fi

# Redis
if docker exec constellation-redis redis-cli -a "${REDIS_PASSWORD:-}" ping 2>/dev/null | grep -q PONG; then
  ok "Redis: constellation-redis"
else
  fail "Redis: constellation-redis not responding"
fi

# ── Workflow Health ──────────────────────────────────────────────────────────
echo -e "\n${BOLD}── Webhook Endpoints ─────────────────────────────────${NC}"

WEBHOOKS=(
  "constellation/event:Master Orchestrator"
  "blue-team/siem-enrichment:BT-01 SIEM Enrichment"
  "iam/offboarding:IAM-02 Offboarding"
  "grc/risk-intake:GRC-02 Risk Register"
  "vuln-mgmt/patch-release:VM-02 Patch Tuesday"
  "ai/enrich:AI-01 Enrichment"
  "dfir/evidence-collect:DFIR-01 Evidence Logger"
)

for wh in "${WEBHOOKS[@]}"; do
  path="${wh%%:*}"
  name="${wh##*:}"
  STATUS=$(curl -sf --max-time 5 -o /dev/null -w "%{http_code}" \
    -X POST "$N8N_URL/webhook/$path" \
    -H "Content-Type: application/json" \
    -d '{"_health_check":true}' 2>/dev/null)
  if [[ "$STATUS" =~ ^(200|201|422|400)$ ]]; then
    ok "$name ($path) — HTTP $STATUS"
  else
    warn "$name ($path) — HTTP $STATUS (workflow may be disabled)"
  fi
done

# ── Database Tables ──────────────────────────────────────────────────────────
echo -e "\n${BOLD}── Database Tables ───────────────────────────────────${NC}"
if command -v psql >/dev/null 2>&1 || docker ps | grep -q constellation-db; then
  TABLE_COUNT=$(docker exec constellation-db psql -U constellation -d constellation -t -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null | tr -d ' ')
  if [[ "$TABLE_COUNT" -ge 30 ]]; then
    ok "DB tables: $TABLE_COUNT (expected ≥ 30)"
  else
    warn "DB tables: $TABLE_COUNT — may need to run init_db_COMPLETE.sql"
  fi

  ALERT_COUNT=$(docker exec constellation-db psql -U constellation -d constellation -t -c \
    "SELECT COUNT(*) FROM bt_alert_log WHERE processed_at >= NOW() - INTERVAL '24 hours';" 2>/dev/null | tr -d ' ')
  [[ "$VERBOSE" == "--verbose" ]] && ok "Alerts (24h): $ALERT_COUNT"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}── Summary ───────────────────────────────────────────${NC}"
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}✅ All checks passed${NC}"
else
  echo -e "${RED}${BOLD}❌ $FAILED check(s) failed — review above${NC}"
fi
echo -e "${CYAN}Hexamind | $(date)${NC}"
