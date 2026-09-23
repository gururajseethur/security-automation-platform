# Workflow catalogue

All 65 workflow definitions in the platform, grouped by domain. Each entry lists its trigger,
the systems it talks to, and the size of the node graph. Every definition is in this repository.

Every workflow sets an error workflow, so a failure raises a ticket rather than disappearing.
Retries back off 30s / 60s / 120s before landing in the dead-letter queue.

| Domain | Workflows |
|---|---|
| Orchestration | 1 |
| AI layer | 1 |
| Blue team | 6 |
| Endpoint | 5 |
| Network | 5 |
| Red team | 5 |
| Vulnerability management | 6 |
| Identity & access | 5 |
| Governance, risk & compliance | 5 |
| Digital forensics & incident response | 5 |
| DevSecOps | 5 |
| Cloud security | 6 |
| Threat intelligence | 5 |
| Security awareness | 5 |
| **Total** | **65** |

## Orchestration

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`CORE-01`](01-orchestrator/master-orchestrator.json) | Master Orchestrator | Event Intake Webhook | HTTP, PostgreSQL, Slack, Webhook | 10 |

## AI layer

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`AI-01`](00-ai-layer/AI-01_ai-threat-enrichment.json) | AI Threat Enrichment Layer (Claude API) | Enrichment Webhook | HTTP, PostgreSQL, Slack, Webhook | 8 |

## Blue team

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`BT-01`](02-blue-team/BT-01_siem-enrichment.json) | SIEM Alert Enrichment & Triage | Receive Alert | HTTP, Jira, PostgreSQL, Slack, Webhook | 11 |
| [`BT-02`](06-phase2/BT-02_ioc-ingestion.json) | Threat Intel IOC Ingestion to SIEM | Every 4 Hours | HTTP, PostgreSQL, Schedule, Slack | 6 |
| [`BT-03`](06-phase2/BT-03_ir-playbook.json) | Incident Response Playbook Engine | Incident Trigger | Jira, PostgreSQL, Slack, Webhook | 5 |
| [`BT-04`](06-phase2/BT-04_fp-tuner.json) | False Positive Auto-Tuner | Weekly Sunday 22:00 | PostgreSQL, Schedule, Slack | 5 |
| [`BT-05`](06-phase2/BT-05_shift-handover.json) | Shift Handover Briefing Generator | Shift End (08:00 & 20:00) | PostgreSQL, Schedule, Slack | 6 |
| [`BT-06`](06-phase2/BT-06_threat-hunt.json) | Threat Hunt Workflow Automation | Hunt Trigger | HTTP, PostgreSQL, Slack, Webhook | 5 |

## Endpoint

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`EP-01`](06-phase2/EP-01_edr-enrichment.json) | EDR Alert Enrichment & Auto-Ticket | EDR Alert Webhook | HTTP, Jira, PostgreSQL, Slack, Webhook | 7 |
| [`EP-02`](06-phase2/EP-02_patch-compliance.json) | Patch Compliance Tracker | Daily 07:00 | HTTP, Jira, Schedule, Slack | 5 |
| [`EP-03`](06-phase2/EP-03_hash-blocker.json) | Malware Hash Auto-Blocker | New Hash Event | HTTP, Slack, Webhook | 7 |
| [`EP-04`](06-phase2/EP-04_unmanaged-device.json) | Unmanaged Device Detector | Daily 04:00 | PostgreSQL, Schedule, Slack | 6 |
| [`EP-05`](06-phase2/EP-05_usb-policy.json) | USB Policy Violation Responder | USB Event Webhook | Jira, PostgreSQL, Slack, Webhook | 5 |

## Network

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`NET-01`](06-phase2/NET-01_fw-auditor.json) | Firewall Rule Hygiene Auditor | Weekly Wednesday 06:00 | HTTP, Jira, Schedule, Slack | 5 |
| [`NET-02`](06-phase2/NET-02_dns-anomaly.json) | DNS Anomaly Detector (DGA + Tunneling) | DNS Event Webhook | HTTP, Jira, Slack, Webhook | 6 |
| [`NET-03`](06-phase2/NET-03_dark-web-monitor.json) | Dark Web Credential Monitor | Daily 06:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |
| [`NET-04`](06-phase2/NET-04_vpn-anomaly.json) | VPN Anomaly & Step-Up Auth | VPN Login Event | HTTP, Slack, Webhook | 5 |
| [`NET-05`](06-phase2/NET-05_baseline-drift.json) | Network Baseline Drift Detector | Weekly Saturday 02:00 | PostgreSQL, Schedule, Slack | 5 |

## Red team

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`RT-01`](06-phase2/RT-01_osint-recon.json) | OSINT Recon Pipeline (Authorized Assets Only) | Weekly Monday 06:00 | HTTP, PostgreSQL, Schedule, Slack | 8 |
| [`RT-02`](06-phase2/RT-02_cve-exploit-triage.json) | CVE → Exploit Triage (Authorized Testing) | Daily 07:00 | HTTP, Jira, PostgreSQL, Schedule, Slack | 6 |
| [`RT-03`](06-phase2/RT-03_phishing-sim.json) | Phishing Simulation Orchestrator | Monthly (15th) | HTTP, PostgreSQL, Schedule, Slack | 4 |
| [`RT-04`](06-phase2/RT-04_attack-surface.json) | Attack Surface Monitor (Diff Detection) | Daily 03:00 | PostgreSQL, Schedule, Slack | 7 |
| [`RT-05`](06-phase2/RT-05_bug-bounty.json) | Bug Bounty Result Ingestion | Every 6 Hours | HTTP, Jira, Schedule, Slack | 5 |

## Vulnerability management

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`VM-01`](03-phase1/VM-01_scanner-aggregator.json) | Vulnerability Scanner Aggregator & Deduplicator | Daily 02:00 | HTTP, Schedule, Slack | 5 |
| [`VM-02`](03-phase1/VM-02_patch-tuesday.json) | Patch Tuesday Automation Pipeline | Patch Release Trigger | HTTP, Jira, Slack, Webhook | 5 |
| [`VM-03`](05-vuln-mgmt/VM-03_cvss-epss-prioritizer.json) | CVSS + EPSS Risk Prioritizer | Daily 06:00 Trigger | HTTP, PostgreSQL, Schedule, Slack | 11 |
| [`VM-04`](08-complete/VM-04_zeroday-warroom.json) | Zero-Day Response War Room | Zero-Day Alert | HTTP, Jira, PostgreSQL, Slack, Webhook | 6 |
| [`VM-05`](08-complete/VM-05_sla-alerter.json) | Vulnerability Aging & SLA Breach Alerter | Daily 09:00 | PostgreSQL, Schedule, Slack | 7 |
| [`VM-06`](08-complete/VM-06_attack-path-mapper.json) | Attack Path Risk Mapper | Weekly Friday 18:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |

## Identity & access

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`IAM-01`](03-phase1/IAM-01_pam-review.json) | Privileged Access Quarterly Review | Quarterly (1 Jan/Apr/Jul/Oct) | HTTP, Jira, Schedule, Slack | 5 |
| [`IAM-02`](04-iam/IAM-02_user-offboarding.json) | User Offboarding Zero-Lag | HR Termination Webhook | HTTP, Jira, PostgreSQL, Slack, Webhook | 13 |
| [`IAM-03`](03-phase1/IAM-03_mfa-enforcer.json) | MFA Enrollment Enforcer | Daily 08:00 | HTTP, Schedule, Slack | 4 |
| [`IAM-04`](08-complete/IAM-04_impossible-travel.json) | Impossible Travel & Login Anomaly Detector | Login Event | HTTP, PostgreSQL, Slack, Webhook | 8 |
| [`IAM-05`](08-complete/IAM-05_shadow-saas.json) | Shadow SaaS Account Hunter | Weekly Sunday 10:00 | HTTP, Jira, Schedule, Slack | 6 |

## Governance, risk & compliance

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`GRC-01`](03-phase1/GRC-01_audit-scheduler.json) | Audit Schedule & Evidence Collector | Monthly Trigger | PostgreSQL, Schedule, Slack | 5 |
| [`GRC-02`](03-phase1/GRC-02_risk-register.json) | Risk Register Lifecycle Manager | Risk Intake | Jira, PostgreSQL, Slack, Webhook | 5 |
| [`GRC-03`](03-phase1/GRC-03_policy-tracker.json) | Policy Acknowledgment Tracker | Policy Published | PostgreSQL, Schedule, Slack, Webhook | 6 |
| [`GRC-04`](03-phase1/GRC-04_vendor-risk.json) | Vendor Risk Assessment Workflow | Vendor Onboard | Jira, PostgreSQL, Slack, Webhook | 5 |
| [`GRC-05`](00-ai-layer/GRC-05_gdpr-breach-pipeline.json) | GDPR Breach 72hr Notification Pipeline | Breach Intake | Jira, PostgreSQL, Schedule, Slack, Webhook | 7 |

## Digital forensics & incident response

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`DFIR-01`](07-phase3/DFIR-01_evidence-logger.json) | Forensic Evidence Auto-Logger | Incident Declared | Jira, PostgreSQL, Slack, Webhook | 7 |
| [`DFIR-02`](07-phase3/DFIR-02_timeline.json) | Unified Timeline Reconstructor | Timeline Request | PostgreSQL, Slack, Webhook | 7 |
| [`DFIR-03`](07-phase3/DFIR-03_sandbox.json) | Malware Sample Auto-Submitter (Any.run) | Suspicious File Event | HTTP, Jira, Slack, Webhook | 9 |
| [`DFIR-04`](07-phase3/DFIR-04_memory-dump.json) | Live Memory Analysis Trigger | Memory Alert | PostgreSQL, Slack, Webhook | 5 |
| [`DFIR-05`](07-phase3/DFIR-05_chain-of-custody.json) | Chain of Custody Tracker | Evidence Access Event | PostgreSQL, Slack, Webhook | 5 |

## DevSecOps

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`DS-01`](07-phase3/DS-01_sast-dast-gate.json) | SAST/DAST Orchestration Gate | PR Created Webhook | HTTP, Slack, Webhook | 6 |
| [`DS-02`](07-phase3/DS-02_dep-sla-monitor.json) | Dependency Vulnerability SLA Monitor | Daily 08:00 | HTTP, Jira, Schedule, Slack | 5 |
| [`DS-04`](07-phase3/DS-04_code-review-assign.json) | Secure Code Review Auto-Assign | PR Files Changed | HTTP, Slack, Webhook | 6 |
| [`DS-05`](07-phase3/DS-05_bug-sla-countdown.json) | Critical Bug Fix SLA Countdown | Critical Finding Created | PostgreSQL, Schedule, Slack, Webhook | 7 |
| [`DS-06`](07-phase3/DS-06_sbom-generator.json) | SBOM Generator & Diff Tracker | Release Tag Webhook | PostgreSQL, Slack, Webhook | 7 |

## Cloud security

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`CS-01`](00-ai-layer/CS-01_cloud-misconfig-scanner.json) | Cloud Misconfiguration Scanner | Every 4 Hours | HTTP, Jira, PostgreSQL, Schedule, Slack | 8 |
| [`CS-02`](08-complete/CS-02_container-gate.json) | Container Image Vulnerability Gate | Image Push Webhook | Jira, Slack, Webhook | 7 |
| [`CS-03`](08-complete/CS-03_iac-gate.json) | Infrastructure-as-Code Security Gate (Checkov) | Terraform PR Webhook | HTTP, Slack, Webhook | 5 |
| [`CS-04`](08-complete/CS-04_cspm-manager.json) | CSPM Finding Manager (Wiz/Prisma) | Daily 07:00 | HTTP, PostgreSQL, Schedule, Slack | 5 |
| [`CS-05`](08-complete/CS-05_cloud-inventory.json) | Cloud Asset Inventory Sync | Daily 01:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |
| [`CS-06`](08-complete/CS-06_iam-permission-auditor.json) | Cloud IAM Over-Permission Auditor | Quarterly | HTTP, Jira, Schedule, Slack | 5 |

## Threat intelligence

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`TI-01`](00-ai-layer/TI-01_daily-intel-brief.json) | AI-Powered Daily Intel Brief | Daily 07:00 | HTTP, Schedule, Slack | 8 |
| [`TI-02`](03-phase1/TI-02_ioc-processor.json) | Malware IOC Feed Processor | Every 4 Hours | HTTP, Schedule, Slack | 5 |
| [`TI-03`](08-complete/TI-03_brand-monitor.json) | Brand & Domain Squatting Monitor | Daily 08:00 | HTTP, Jira, PostgreSQL, Schedule, Slack | 7 |
| [`TI-04`](08-complete/TI-04_ttp-profiler.json) | Threat Actor TTP Profiler (MITRE ATT&CK) | Weekly Monday 07:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |
| [`TI-05`](08-complete/TI-05_geo-threat-adaptor.json) | Geopolitical Threat Level Adaptor | Weekly Monday 06:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |

## Security awareness

| ID | Workflow | Trigger | Integrations | Nodes |
|---|---|---|---|---|
| [`AWR-01`](07-phase3/AWR-01_phishing-tracker.json) | Phishing Simulation Results Tracker | Weekly Monday 09:00 | HTTP, PostgreSQL, Schedule, Slack | 5 |
| [`AWR-02`](07-phase3/AWR-02_training-compliance.json) | Security Training Compliance Monitor | Daily 09:00 | HTTP, Jira, Schedule, Slack | 5 |
| [`AWR-03`](07-phase3/AWR-03_threat-digest.json) | Weekly Staff Threat Digest Emailer | Friday 16:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |
| [`AWR-04`](07-phase3/AWR-04_password-alerter.json) | Password Policy Violation Alerter | Password Violation Event | HTTP, PostgreSQL, Slack, Webhook | 5 |
| [`AWR-05`](07-phase3/AWR-05_champion-leaderboard.json) | Security Champion Leaderboard | Friday 17:00 | PostgreSQL, Schedule, Slack | 5 |
