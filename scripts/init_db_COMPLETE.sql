-- ═══════════════════════════════════════════════════════════════════════════════
-- CYBER CONSTELLATION — COMPLETE DATABASE SCHEMA
-- Run this single file to initialize all tables across all phases
-- Version: 1.2 | Last updated: 2026-04
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── ORCHESTRATOR ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS constellation_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(64) UNIQUE NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    source VARCHAR(128),
    event_type VARCHAR(128),
    severity VARCHAR(32),
    severity_score INTEGER,
    confidence_score INTEGER,
    risk_level VARCHAR(32),
    target_agent VARCHAR(128),
    routing_error BOOLEAN DEFAULT FALSE,
    raw_payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS constellation_errors (
    id SERIAL PRIMARY KEY,
    error_id VARCHAR(64) UNIQUE NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    workflow_name VARCHAR(128),
    execution_id VARCHAR(64),
    failed_node VARCHAR(128),
    error_message TEXT,
    error_type VARCHAR(32),
    retry_count INTEGER DEFAULT 0,
    should_retry BOOLEAN DEFAULT FALSE,
    severity VARCHAR(16),
    original_payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS correlated_incidents (
    id SERIAL PRIMARY KEY,
    correlation_id VARCHAR(64) UNIQUE NOT NULL,
    type VARCHAR(32),
    pivot VARCHAR(256),
    severity VARCHAR(16),
    alert_count INTEGER,
    unique_rules INTEGER,
    unique_ips INTEGER,
    duration_minutes INTEGER,
    narrative TEXT,
    mitre_hypothesis VARCHAR(256),
    recommended_action TEXT,
    first_seen TIMESTAMPTZ,
    last_seen TIMESTAMPTZ,
    jira_key VARCHAR(32),
    analyst VARCHAR(128),
    resolution TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS analyst_feedback (
    id SERIAL PRIMARY KEY,
    feedback_id VARCHAR(64) UNIQUE NOT NULL,
    submitted_at TIMESTAMPTZ NOT NULL,
    alert_id VARCHAR(64),
    rule_id VARCHAR(64),
    workflow_name VARCHAR(128),
    analyst VARCHAR(128),
    verdict VARCHAR(32) CHECK (verdict IN ('true_positive','false_positive','noise','needs_tuning')),
    confidence_at_time INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rule_thresholds (
    id SERIAL PRIMARY KEY,
    rule_id VARCHAR(64) UNIQUE NOT NULL,
    confidence_threshold INTEGER DEFAULT 75,
    fp_rate NUMERIC(5,1),
    recommendation VARCHAR(32),
    total_verdicts INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── BLUE TEAM / SOC ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bt_alert_log (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(64) UNIQUE,
    rule_id VARCHAR(64),
    rule_desc TEXT,
    severity VARCHAR(32),
    src_ip VARCHAR(64),
    dst_ip VARCHAR(64),
    username VARCHAR(128),
    agent_name VARCHAR(128),
    agent_id VARCHAR(64),
    confidence_score INTEGER,
    vt_score INTEGER,
    vt_malicious_count INTEGER,
    geo_country VARCHAR(64),
    geo_city VARCHAR(64),
    geo_org VARCHAR(256),
    is_vpn BOOLEAN,
    is_high_risk_geo BOOLEAN,
    asset_criticality VARCHAR(32),
    triage_decision VARCHAR(64),
    jira_key VARCHAR(32),
    kill_chain_stage VARCHAR(64),
    ai_narrative TEXT,
    ai_urgency VARCHAR(32),
    ai_verdict_hint VARCHAR(32),
    ai_enriched_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS incidents (
    id SERIAL PRIMARY KEY,
    incident_id VARCHAR(64) UNIQUE NOT NULL,
    type VARCHAR(64),
    playbook VARCHAR(128),
    severity VARCHAR(32),
    team VARCHAR(64),
    sla_hours NUMERIC(5,1),
    due_at TIMESTAMPTZ,
    jira_key VARCHAR(32),
    status VARCHAR(32) DEFAULT 'Open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS threat_hunts (
    id SERIAL PRIMARY KEY,
    hunt_id VARCHAR(64) UNIQUE NOT NULL,
    hypothesis TEXT,
    query_count INTEGER DEFAULT 0,
    hunter VARCHAR(128),
    status VARCHAR(32) DEFAULT 'Active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

-- ─── GRC / COMPLIANCE ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_controls (
    id SERIAL PRIMARY KEY,
    control_id VARCHAR(64) UNIQUE NOT NULL,
    control_name VARCHAR(256),
    framework VARCHAR(64),
    owner_email VARCHAR(256),
    evidence_types TEXT[],
    last_evidence_date TIMESTAMPTZ,
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS audit_evidence_requests (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(64) UNIQUE NOT NULL,
    owner_email VARCHAR(256),
    control_count INTEGER,
    due_date DATE,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    fulfilled_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS risk_register (
    id SERIAL PRIMARY KEY,
    risk_id VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(256),
    description TEXT,
    category VARCHAR(64),
    score INTEGER,
    risk_level VARCHAR(32),
    owner_email VARCHAR(256),
    review_due DATE,
    status VARCHAR(32) DEFAULT 'Open',
    jira_key VARCHAR(32),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS policy_acknowledgments (
    id SERIAL PRIMARY KEY,
    tracking_id VARCHAR(64) UNIQUE NOT NULL,
    policy_id VARCHAR(64),
    policy_name VARCHAR(256),
    employee_id VARCHAR(64),
    email VARCHAR(256),
    department VARCHAR(128),
    manager_email VARCHAR(256),
    deadline TIMESTAMPTZ,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vendor_risk_register (
    id SERIAL PRIMARY KEY,
    vendor_id VARCHAR(64) UNIQUE NOT NULL,
    vendor_name VARCHAR(256),
    risk_score INTEGER,
    risk_level VARCHAR(32),
    recommended_action TEXT,
    jira_key VARCHAR(32),
    review_due DATE,
    status VARCHAR(32) DEFAULT 'Pending Review',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gdpr_breach_log (
    id SERIAL PRIMARY KEY,
    breach_id VARCHAR(64) UNIQUE NOT NULL,
    breach_type VARCHAR(64),
    affected_records INTEGER,
    must_notify BOOLEAN DEFAULT FALSE,
    discovery_time TIMESTAMPTZ,
    deadline_72h TIMESTAMPTZ,
    notification_submitted BOOLEAN DEFAULT FALSE,
    jira_key VARCHAR(32),
    risk_level VARCHAR(16),
    evidence_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── IAM / ACCESS CONTROL ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS iam_offboarding_log (
    id SERIAL PRIMARY KEY,
    offboarding_id VARCHAR(64) UNIQUE NOT NULL,
    employee_id VARCHAR(64),
    email VARCHAR(256),
    full_name VARCHAR(256),
    department VARCHAR(128),
    effective_date TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    sla_met BOOLEAN,
    success_count INTEGER,
    failure_count INTEGER DEFAULT 0,
    offboarding_complete BOOLEAN DEFAULT FALSE,
    jira_key VARCHAR(32),
    evidence_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS iam_login_history (
    id SERIAL PRIMARY KEY,
    username VARCHAR(128),
    src_ip INET,
    country VARCHAR(64),
    city VARCHAR(128),
    login_time TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staff (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(64) UNIQUE NOT NULL,
    email VARCHAR(256) UNIQUE NOT NULL,
    full_name VARCHAR(256),
    department VARCHAR(128),
    manager_email VARCHAR(256),
    active BOOLEAN DEFAULT TRUE,
    phishing_sim_authorized BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staff_email_domains (
    id SERIAL PRIMARY KEY,
    email_domain VARCHAR(128) UNIQUE NOT NULL,
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS password_violations (
    id SERIAL PRIMARY KEY,
    violation_id VARCHAR(64) UNIQUE NOT NULL,
    username VARCHAR(128),
    email VARCHAR(256),
    violation_type VARCHAR(64),
    severity VARCHAR(32),
    deadline TIMESTAMPTZ,
    status VARCHAR(32) DEFAULT 'Pending',
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── VULNERABILITY MANAGEMENT ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS vulnerabilities (
    id SERIAL PRIMARY KEY,
    cve_id VARCHAR(32) UNIQUE NOT NULL,
    cvss_score NUMERIC(4,1),
    cvss_v3 NUMERIC(4,1),
    cvss_vector VARCHAR(128),
    attack_vector VARCHAR(32),
    cwe VARCHAR(32),
    vuln_description TEXT,
    epss_score NUMERIC(8,6),
    epss_percentile NUMERIC(5,2),
    composite_score INTEGER,
    priority_tier VARCHAR(32),
    sla_days INTEGER,
    sla_due_date DATE,
    sla_breached BOOLEAN DEFAULT FALSE,
    status VARCHAR(32) DEFAULT 'open',
    asset_id VARCHAR(64),
    asset_criticality VARCHAR(32),
    assigned_to VARCHAR(128),
    jira_key VARCHAR(32),
    days_open INTEGER DEFAULT 0,
    last_scored_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vulnerability_score_history (
    id SERIAL PRIMARY KEY,
    cve_id VARCHAR(32) NOT NULL,
    composite_score INTEGER,
    epss_score NUMERIC(8,6),
    priority_tier VARCHAR(16),
    sla_breached BOOLEAN DEFAULT FALSE,
    scored_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (cve_id, scored_date)
);

CREATE TABLE IF NOT EXISTS sla_breach_alerts (
    id SERIAL PRIMARY KEY,
    cve_id VARCHAR(32),
    alerted_at TIMESTAMPTZ DEFAULT NOW(),
    priority_tier VARCHAR(32),
    UNIQUE (cve_id, alerted_at::date)
);

CREATE TABLE IF NOT EXISTS zero_day_incidents (
    id SERIAL PRIMARY KEY,
    war_room_id VARCHAR(64) UNIQUE NOT NULL,
    cve_id VARCHAR(32),
    title VARCHAR(256),
    cvss_score NUMERIC(4,1),
    exploited_in_wild BOOLEAN DEFAULT FALSE,
    jira_key VARCHAR(32),
    status VARCHAR(32) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS appsec_sla_timers (
    id SERIAL PRIMARY KEY,
    finding_id VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(256),
    severity VARCHAR(32),
    repo VARCHAR(256),
    assignee VARCHAR(128),
    sla_hours INTEGER,
    deadline TIMESTAMPTZ,
    jira_key VARCHAR(32),
    status VARCHAR(32) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sbom_registry (
    id SERIAL PRIMARY KEY,
    release_id VARCHAR(64) UNIQUE NOT NULL,
    repo VARCHAR(256),
    tag VARCHAR(64),
    commit_sha VARCHAR(64),
    component_count INTEGER,
    sbom_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── CLOUD SECURITY ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cloud_scan_log (
    id SERIAL PRIMARY KEY,
    scan_timestamp TIMESTAMPTZ,
    critical_count INTEGER DEFAULT 0,
    high_count INTEGER DEFAULT 0,
    total_findings INTEGER DEFAULT 0,
    findings_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cloud_posture_findings (
    id SERIAL PRIMARY KEY,
    finding_id VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(256),
    severity VARCHAR(32),
    resource VARCHAR(256),
    resource_type VARCHAR(64),
    sla_days INTEGER,
    age_days INTEGER DEFAULT 0,
    sla_breached BOOLEAN DEFAULT FALSE,
    status VARCHAR(32) DEFAULT 'Open',
    jira_key VARCHAR(32),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geopolitical_assessments (
    id SERIAL PRIMARY KEY,
    threat_level VARCHAR(32),
    sensitivity_multiplier NUMERIC(4,2) DEFAULT 1.0,
    kev_count INTEGER DEFAULT 0,
    notes TEXT,
    assessed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── NETWORK SECURITY ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS attack_surface_baseline (
    id SERIAL PRIMARY KEY,
    asset_id VARCHAR(64),
    ip_address INET,
    open_ports_json JSONB,
    services_json JSONB,
    scanned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (asset_id, scanned_at::date)
);

CREATE TABLE IF NOT EXISTS network_baseline (
    id SERIAL PRIMARY KEY,
    ip_address INET UNIQUE,
    hostname VARCHAR(256),
    open_ports_json JSONB,
    last_seen TIMESTAMPTZ DEFAULT NOW()
);

-- ─── THREAT INTELLIGENCE ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS threat_iocs (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(64),
    type VARCHAR(32),
    value TEXT UNIQUE NOT NULL,
    hash_type VARCHAR(16),
    malware_family VARCHAR(128),
    confidence INTEGER DEFAULT 75,
    source VARCHAR(64),
    tags TEXT,
    active BOOLEAN DEFAULT TRUE,
    first_seen TIMESTAMPTZ,
    last_seen TIMESTAMPTZ,
    ingested_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS threat_actor_profiles (
    id SERIAL PRIMARY KEY,
    actor_name VARCHAR(128),
    campaign_name VARCHAR(256) UNIQUE,
    ttp_count INTEGER DEFAULT 0,
    ioc_count INTEGER DEFAULT 0,
    targeted_industries TEXT[],
    tlp VARCHAR(16),
    source_pulse VARCHAR(64),
    discovered_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS protected_domains (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR(256) UNIQUE NOT NULL,
    active BOOLEAN DEFAULT TRUE
);

-- ─── DFIR / FORENSICS ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS dfir_cases (
    id SERIAL PRIMARY KEY,
    case_id VARCHAR(64) UNIQUE NOT NULL,
    incident_id VARCHAR(64),
    hosts_json JSONB,
    severity VARCHAR(32),
    declared_by VARCHAR(128),
    declared_at TIMESTAMPTZ,
    evidence_location TEXT,
    status VARCHAR(32) DEFAULT 'Active',
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dfir_evidence_log (
    id SERIAL PRIMARY KEY,
    case_id VARCHAR(64),
    task_type VARCHAR(64),
    host VARCHAR(256),
    file_path TEXT,
    file_hash VARCHAR(128),
    status VARCHAR(32) DEFAULT 'Planned',
    collected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dfir_chain_of_custody (
    id SERIAL PRIMARY KEY,
    coc_id VARCHAR(64) UNIQUE NOT NULL,
    case_id VARCHAR(64),
    evidence_id VARCHAR(64),
    action VARCHAR(32),
    accessed_by VARCHAR(128),
    accessed_from VARCHAR(128),
    timestamp TIMESTAMPTZ,
    evidence_hash VARCHAR(128),
    notes TEXT,
    signature VARCHAR(128),
    legal_hold BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dfir_timelines (
    id SERIAL PRIMARY KEY,
    case_id VARCHAR(64),
    analyst VARCHAR(128),
    total_events INTEGER DEFAULT 0,
    spike_count INTEGER DEFAULT 0,
    first_event TIMESTAMPTZ,
    last_event TIMESTAMPTZ,
    built_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dfir_memory_tasks (
    id SERIAL PRIMARY KEY,
    analysis_id VARCHAR(64) UNIQUE NOT NULL,
    case_id VARCHAR(64),
    hostname VARCHAR(256),
    plugins_json JSONB,
    status VARCHAR(32) DEFAULT 'Running',
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- ─── AI ENRICHMENT ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_enrichment_log (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(64),
    model_used VARCHAR(64),
    kill_chain_stage VARCHAR(64),
    urgency VARCHAR(32),
    analyst_verdict_hint VARCHAR(32),
    tokens_used INTEGER,
    confidence_in_analysis INTEGER,
    narrative TEXT,
    mitre_json JSONB,
    actions_json JSONB,
    enriched_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── AWARENESS / TRAINING ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS phishing_campaign_results (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER UNIQUE,
    campaign_name VARCHAR(256),
    sent INTEGER DEFAULT 0,
    opened INTEGER DEFAULT 0,
    clicked INTEGER DEFAULT 0,
    cred_submitted INTEGER DEFAULT 0,
    click_rate NUMERIC(5,1) DEFAULT 0,
    analysed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_completions (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(64),
    training_campaign_name VARCHAR(256),
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── RECON / RED TEAM ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS recon_reports (
    id SERIAL PRIMARY KEY,
    recon_id VARCHAR(64) UNIQUE NOT NULL,
    asset_count INTEGER DEFAULT 0,
    finding_count INTEGER DEFAULT 0,
    critical_count INTEGER DEFAULT 0,
    findings_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── CMDB ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cmdb_assets (
    id SERIAL PRIMARY KEY,
    asset_id VARCHAR(64) UNIQUE NOT NULL,
    hostname VARCHAR(256),
    ip_address INET,
    mac_address VARCHAR(32),
    os VARCHAR(128),
    owner_team VARCHAR(128),
    owner_email VARCHAR(256),
    environment VARCHAR(32) DEFAULT 'production',
    asset_type VARCHAR(64) DEFAULT 'server',
    criticality VARCHAR(32) DEFAULT 'medium',
    domain VARCHAR(128),
    recon_authorized BOOLEAN DEFAULT FALSE,
    tags JSONB,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── MDM ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mdm_devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(64) UNIQUE NOT NULL,
    hostname VARCHAR(256),
    mac_address VARCHAR(32),
    owner_email VARCHAR(256),
    enrolled BOOLEAN DEFAULT TRUE,
    last_checkin TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_bt_alert_processed ON bt_alert_log(processed_at DESC);
CREATE INDEX IF NOT EXISTS idx_bt_alert_severity ON bt_alert_log(severity);
CREATE INDEX IF NOT EXISTS idx_bt_alert_src_ip ON bt_alert_log(src_ip);
CREATE INDEX IF NOT EXISTS idx_bt_alert_rule ON bt_alert_log(rule_id);
CREATE INDEX IF NOT EXISTS idx_corr_severity ON correlated_incidents(severity);
CREATE INDEX IF NOT EXISTS idx_corr_created ON correlated_incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_rule ON analyst_feedback(rule_id);
CREATE INDEX IF NOT EXISTS idx_feedback_verdict ON analyst_feedback(verdict);
CREATE INDEX IF NOT EXISTS idx_feedback_submitted ON analyst_feedback(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_vulns_composite ON vulnerabilities(composite_score DESC);
CREATE INDEX IF NOT EXISTS idx_vulns_status ON vulnerabilities(status);
CREATE INDEX IF NOT EXISTS idx_vulns_sla ON vulnerabilities(sla_breached);
CREATE INDEX IF NOT EXISTS idx_vuln_hist_cve ON vulnerability_score_history(cve_id);
CREATE INDEX IF NOT EXISTS idx_vuln_hist_date ON vulnerability_score_history(scored_date DESC);
CREATE INDEX IF NOT EXISTS idx_iocs_value ON threat_iocs(value);
CREATE INDEX IF NOT EXISTS idx_iocs_type ON threat_iocs(type);
CREATE INDEX IF NOT EXISTS idx_iocs_active ON threat_iocs(active, ingested_at DESC);
CREATE INDEX IF NOT EXISTS idx_cmdb_ip ON cmdb_assets(ip_address);
CREATE INDEX IF NOT EXISTS idx_cmdb_hostname ON cmdb_assets(hostname);
CREATE INDEX IF NOT EXISTS idx_constellation_events_type ON constellation_events(event_type);
CREATE INDEX IF NOT EXISTS idx_constellation_events_received ON constellation_events(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_errors_workflow ON constellation_errors(workflow_name);
CREATE INDEX IF NOT EXISTS idx_login_history_user ON iam_login_history(username, login_time DESC);

-- ─── SEED DATA ───────────────────────────────────────────────────────────────

INSERT INTO cmdb_assets (asset_id,hostname,ip_address,environment,criticality,owner_team,asset_type,recon_authorized) VALUES
  ('ASSET-001','prod-web-01','10.0.1.10','production','critical','Engineering','server',true),
  ('ASSET-002','prod-db-01','10.0.1.20','production','critical','DBA Team','server',true),
  ('ASSET-003','prod-api-01','10.0.1.30','production','critical','Engineering','server',true),
  ('ASSET-004','staging-web-01','10.0.2.10','staging','medium','Engineering','server',false),
  ('ASSET-005','vpn-gw-01','10.0.0.1','production','high','Infrastructure','network',true)
ON CONFLICT (asset_id) DO NOTHING;

INSERT INTO protected_domains (domain_name) VALUES
  ('yourdomain.com'),
  ('yourcompany.in')
ON CONFLICT (domain_name) DO NOTHING;

INSERT INTO staff_email_domains (email_domain) VALUES
  ('yourdomain.com')
ON CONFLICT (email_domain) DO NOTHING;

-- SLA breach alerts table unique constraint fix
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='sla_breach_alerts_cve_date_unique'
  ) THEN
    ALTER TABLE sla_breach_alerts ADD CONSTRAINT sla_breach_alerts_cve_date_unique
      UNIQUE (cve_id, (alerted_at::date));
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

SELECT
  COUNT(*) as total_tables,
  NOW() as initialized_at,
  'Cyber Constellation DB ready' as status
FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE';

-- ─── USB EVENTS (EP-05) ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usb_events (
    id SERIAL PRIMARY KEY,
    hostname VARCHAR(256),
    username VARCHAR(128),
    device_id VARCHAR(128),
    action VARCHAR(32),
    data_classification VARCHAR(64),
    bytes_transferred BIGINT DEFAULT 0,
    severity VARCHAR(32),
    jira_key VARCHAR(32),
    event_time TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_usb_events_username ON usb_events(username);
CREATE INDEX IF NOT EXISTS idx_usb_events_severity ON usb_events(severity);
