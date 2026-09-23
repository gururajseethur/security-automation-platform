-- =====================================================================
-- CYBER CONSTELLATION - MULTI-TENANCY SCHEMA
-- Run after init_db_COMPLETE.sql
-- Adds tenant isolation, billing, and usage metering
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- TENANTS
CREATE TABLE IF NOT EXISTS tenants (
    id              SERIAL PRIMARY KEY,
    tenant_id       VARCHAR(32) UNIQUE NOT NULL,
    tenant_name     VARCHAR(256) NOT NULL,
    admin_email     VARCHAR(256) NOT NULL,
    plan            VARCHAR(32) NOT NULL CHECK (plan IN ('starter','professional','enterprise')),
    webhook_secret  VARCHAR(128) NOT NULL,
    active          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    trial_ends_at   TIMESTAMPTZ,
    notes           TEXT
);

CREATE TABLE IF NOT EXISTS tenant_plans (
    id              SERIAL PRIMARY KEY,
    tenant_id       VARCHAR(32) REFERENCES tenants(tenant_id),
    plan            VARCHAR(32),
    event_limit     INTEGER,
    ai_call_limit   INTEGER,
    workflow_limit  INTEGER,
    analyst_seats   INTEGER,
    price_usd_month NUMERIC(10,2),
    billing_anchor  DATE DEFAULT CURRENT_DATE,
    UNIQUE (tenant_id)
);

CREATE TABLE IF NOT EXISTS sentinel_users (
    id              SERIAL PRIMARY KEY,
    user_id         VARCHAR(64) UNIQUE NOT NULL DEFAULT gen_random_uuid()::text,
    tenant_id       VARCHAR(32) REFERENCES tenants(tenant_id),
    username        VARCHAR(128) NOT NULL,
    email           VARCHAR(256) NOT NULL,
    password_hash   VARCHAR(128),
    role            VARCHAR(32) NOT NULL CHECK (role IN ('analyst','lead','admin','superadmin')),
    active          BOOLEAN DEFAULT TRUE,
    last_login      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (tenant_id, username)
);

CREATE TABLE IF NOT EXISTS usage_events (
    id              SERIAL PRIMARY KEY,
    tenant_id       VARCHAR(32) REFERENCES tenants(tenant_id),
    event_type      VARCHAR(64),
    workflow_name   VARCHAR(128),
    tokens_used     INTEGER DEFAULT 0,
    recorded_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ADD tenant_id COLUMN TO ALL CORE TABLES
DO $$
DECLARE
    tbl TEXT;
    tables TEXT[] := ARRAY[
        'bt_alert_log','correlated_incidents','analyst_feedback','rule_thresholds',
        'constellation_events','constellation_errors','vulnerabilities',
        'vulnerability_score_history','risk_register','incidents',
        'iam_offboarding_log','cloud_posture_findings','dfir_cases',
        'threat_iocs','threat_actor_profiles','gdpr_breach_log',
        'zero_day_incidents','appsec_sla_timers'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = tbl AND column_name = 'tenant_id'
        ) THEN
            EXECUTE format('ALTER TABLE %I ADD COLUMN tenant_id VARCHAR(32) DEFAULT ''default''', tbl);
            EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_tenant ON %I(tenant_id)', tbl, tbl);
        END IF;
    END LOOP;
END $$;

-- DEFAULT TENANT
INSERT INTO tenants (tenant_id, tenant_name, admin_email, plan, webhook_secret)
VALUES ('default', 'Default Tenant', 'admin@localhost', 'enterprise', 'change-this-secret')
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO tenant_plans (tenant_id, plan, event_limit, ai_call_limit, workflow_limit, analyst_seats, price_usd_month)
VALUES ('default', 'enterprise', NULL, NULL, NULL, NULL, 0)
ON CONFLICT (tenant_id) DO NOTHING;

-- PLAN DEFINITIONS
CREATE TABLE IF NOT EXISTS plan_definitions (
    plan            VARCHAR(32) PRIMARY KEY,
    event_limit     INTEGER,
    ai_call_limit   INTEGER,
    workflow_limit  INTEGER,
    analyst_seats   INTEGER,
    price_usd_month NUMERIC(10,2),
    features        JSONB
);

INSERT INTO plan_definitions VALUES
('starter',      10000,  500,   20,  3,   299.00,  '{"siem":true,"vuln":true,"grc":false,"dfir":false,"ai":true}'),
('professional', 100000, 5000,  50,  10,  999.00,  '{"siem":true,"vuln":true,"grc":true,"dfir":false,"ai":true}'),
('enterprise',   NULL,   NULL,  NULL, NULL, NULL, '{"siem":true,"vuln":true,"grc":true,"dfir":true,"ai":true,"white_label":true,"custom_integrations":true}')
ON CONFLICT (plan) DO UPDATE
SET price_usd_month = EXCLUDED.price_usd_month,
    features = EXCLUDED.features;

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_usage_tenant_month ON usage_events(tenant_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_usage_type ON usage_events(event_type);
CREATE INDEX IF NOT EXISTS idx_sentinel_users_tenant ON sentinel_users(tenant_id);

SELECT 'Multi-tenancy schema applied' AS status, COUNT(*) AS tables_with_tenant_id
FROM information_schema.columns
WHERE column_name = 'tenant_id' AND table_schema = 'public';
