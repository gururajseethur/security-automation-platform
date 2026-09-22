# Workflow catalogue

All 65 workflow definitions in the platform, grouped by domain. Each entry lists its trigger,
the systems it talks to, and the size of the node graph.

Every workflow sets an error workflow, so a failure raises a ticket rather than disappearing.
Retries back off 30s / 60s / 120s before landing in the dead-letter queue.

> The six workflows marked **shipped** are included in this repository as full n8n exports, chosen
> to cover the range: orchestration, alert enrichment, risk scoring, a destructive multi-system
> action, a regulatory clock, and a behavioural detection. The remaining definitions are catalogued
> here but not exported, since an n8n JSON is largely node coordinates and reads poorly out of context.

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

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `CORE-01` | Master Orchestrator | Event Intake Webhook | HTTP, PostgreSQL, Slack, Webhook | 10 | [**shipped**](01-orchestrator/master-orchestrator.json) |

## AI layer

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `AI-01` | AI Threat Enrichment Layer (Claude API) | Enrichment Webhook | HTTP, PostgreSQL, Slack, Webhook | 8 |  |

## Blue team

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `BT-01` | SIEM Alert Enrichment & Triage | Receive Alert | HTTP, Jira, PostgreSQL, Slack, Webhook | 11 | [**shipped**](02-blue-team/BT-01_siem-enrichment.json) |
| `BT-02` | Threat Intel IOC Ingestion to SIEM | Every 4 Hours | HTTP, PostgreSQL, Schedule, Slack | 6 |  |
| `BT-03` | Incident Response Playbook Engine | Incident Trigger | Jira, PostgreSQL, Slack, Webhook | 5 |  |
| `BT-04` | False Positive Auto-Tuner | Weekly Sunday 22:00 | PostgreSQL, Schedule, Slack | 5 |  |
| `BT-05` | Shift Handover Briefing Generator | Shift End (08:00 & 20:00) | PostgreSQL, Schedule, Slack | 6 |  |
| `BT-06` | Threat Hunt Workflow Automation | Hunt Trigger | HTTP, PostgreSQL, Slack, Webhook | 5 |  |

## Endpoint

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `EP-01` | EDR Alert Enrichment & Auto-Ticket | EDR Alert Webhook | HTTP, Jira, PostgreSQL, Slack, Webhook | 7 |  |
| `EP-02` | Patch Compliance Tracker | Daily 07:00 | HTTP, Jira, Schedule, Slack | 5 |  |
| `EP-03` | Malware Hash Auto-Blocker | New Hash Event | HTTP, Slack, Webhook | 7 |  |
| `EP-04` | Unmanaged Device Detector | Daily 04:00 | PostgreSQL, Schedule, Slack | 6 |  |
| `EP-05` | USB Policy Violation Responder | USB Event Webhook | Jira, PostgreSQL, Slack, Webhook | 5 |  |

## Network

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `NET-01` | Firewall Rule Hygiene Auditor | Weekly Wednesday 06:00 | HTTP, Jira, Schedule, Slack | 5 |  |
| `NET-02` | DNS Anomaly Detector (DGA + Tunneling) | DNS Event Webhook | HTTP, Jira, Slack, Webhook | 6 |  |
| `NET-03` | Dark Web Credential Monitor | Daily 06:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |
| `NET-04` | VPN Anomaly & Step-Up Auth | VPN Login Event | HTTP, Slack, Webhook | 5 |  |
| `NET-05` | Network Baseline Drift Detector | Weekly Saturday 02:00 | PostgreSQL, Schedule, Slack | 5 |  |

## Red team

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `RT-01` | OSINT Recon Pipeline (Authorized Assets Only) | Weekly Monday 06:00 | HTTP, PostgreSQL, Schedule, Slack | 8 |  |
| `RT-02` | CVE → Exploit Triage (Authorized Testing) | Daily 07:00 | HTTP, Jira, PostgreSQL, Schedule, Slack | 6 |  |
| `RT-03` | Phishing Simulation Orchestrator | Monthly (15th) | HTTP, PostgreSQL, Schedule, Slack | 4 |  |
| `RT-04` | Attack Surface Monitor (Diff Detection) | Daily 03:00 | PostgreSQL, Schedule, Slack | 7 |  |
| `RT-05` | Bug Bounty Result Ingestion | Every 6 Hours | HTTP, Jira, Schedule, Slack | 5 |  |

## Vulnerability management

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `VM-01` | Vulnerability Scanner Aggregator & Deduplicator | Daily 02:00 | HTTP, Schedule, Slack | 5 |  |
| `VM-02` | Patch Tuesday Automation Pipeline | Patch Release Trigger | HTTP, Jira, Slack, Webhook | 5 |  |
| `VM-03` | CVSS + EPSS Risk Prioritizer | Daily 06:00 Trigger | HTTP, PostgreSQL, Schedule, Slack | 11 | [**shipped**](05-vuln-mgmt/VM-03_cvss-epss-prioritizer.json) |
| `VM-04` | Zero-Day Response War Room | Zero-Day Alert | HTTP, Jira, PostgreSQL, Slack, Webhook | 6 |  |
| `VM-05` | Vulnerability Aging & SLA Breach Alerter | Daily 09:00 | PostgreSQL, Schedule, Slack | 7 |  |
| `VM-06` | Attack Path Risk Mapper | Weekly Friday 18:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |

## Identity & access

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `IAM-01` | Privileged Access Quarterly Review | Quarterly (1 Jan/Apr/Jul/Oct) | HTTP, Jira, Schedule, Slack | 5 |  |
| `IAM-02` | User Offboarding Zero-Lag | HR Termination Webhook | HTTP, Jira, PostgreSQL, Slack, Webhook | 13 | [**shipped**](04-iam/IAM-02_user-offboarding.json) |
| `IAM-03` | MFA Enrollment Enforcer | Daily 08:00 | HTTP, Schedule, Slack | 4 |  |
| `IAM-04` | Impossible Travel & Login Anomaly Detector | Login Event | HTTP, PostgreSQL, Slack, Webhook | 8 | [**shipped**](08-complete/IAM-04_impossible-travel.json) |
| `IAM-05` | Shadow SaaS Account Hunter | Weekly Sunday 10:00 | HTTP, Jira, Schedule, Slack | 6 |  |

## Governance, risk & compliance

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `GRC-01` | Audit Schedule & Evidence Collector | Monthly Trigger | PostgreSQL, Schedule, Slack | 5 |  |
| `GRC-02` | Risk Register Lifecycle Manager | Risk Intake | Jira, PostgreSQL, Slack, Webhook | 5 |  |
| `GRC-03` | Policy Acknowledgment Tracker | Policy Published | PostgreSQL, Schedule, Slack, Webhook | 6 |  |
| `GRC-04` | Vendor Risk Assessment Workflow | Vendor Onboard | Jira, PostgreSQL, Slack, Webhook | 5 |  |
| `GRC-05` | GDPR Breach 72hr Notification Pipeline | Breach Intake | Jira, PostgreSQL, Schedule, Slack, Webhook | 7 | [**shipped**](00-ai-layer/GRC-05_gdpr-breach-pipeline.json) |

## Digital forensics & incident response

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `DFIR-01` | Forensic Evidence Auto-Logger | Incident Declared | Jira, PostgreSQL, Slack, Webhook | 7 |  |
| `DFIR-02` | Unified Timeline Reconstructor | Timeline Request | PostgreSQL, Slack, Webhook | 7 |  |
| `DFIR-03` | Malware Sample Auto-Submitter (Any.run) | Suspicious File Event | HTTP, Jira, Slack, Webhook | 9 |  |
| `DFIR-04` | Live Memory Analysis Trigger | Memory Alert | PostgreSQL, Slack, Webhook | 5 |  |
| `DFIR-05` | Chain of Custody Tracker | Evidence Access Event | PostgreSQL, Slack, Webhook | 5 |  |

## DevSecOps

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `DS-01` | SAST/DAST Orchestration Gate | PR Created Webhook | HTTP, Slack, Webhook | 6 |  |
| `DS-02` | Dependency Vulnerability SLA Monitor | Daily 08:00 | HTTP, Jira, Schedule, Slack | 5 |  |
| `DS-04` | Secure Code Review Auto-Assign | PR Files Changed | HTTP, Slack, Webhook | 6 |  |
| `DS-05` | Critical Bug Fix SLA Countdown | Critical Finding Created | PostgreSQL, Schedule, Slack, Webhook | 7 |  |
| `DS-06` | SBOM Generator & Diff Tracker | Release Tag Webhook | PostgreSQL, Slack, Webhook | 7 |  |

## Cloud security

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `CS-01` | Cloud Misconfiguration Scanner | Every 4 Hours | HTTP, Jira, PostgreSQL, Schedule, Slack | 8 |  |
| `CS-02` | Container Image Vulnerability Gate | Image Push Webhook | Jira, Slack, Webhook | 7 |  |
| `CS-03` | Infrastructure-as-Code Security Gate (Checkov) | Terraform PR Webhook | HTTP, Slack, Webhook | 5 |  |
| `CS-04` | CSPM Finding Manager (Wiz/Prisma) | Daily 07:00 | HTTP, PostgreSQL, Schedule, Slack | 5 |  |
| `CS-05` | Cloud Asset Inventory Sync | Daily 01:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |
| `CS-06` | Cloud IAM Over-Permission Auditor | Quarterly | HTTP, Jira, Schedule, Slack | 5 |  |

## Threat intelligence

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `TI-01` | AI-Powered Daily Intel Brief | Daily 07:00 | HTTP, Schedule, Slack | 8 |  |
| `TI-02` | Malware IOC Feed Processor | Every 4 Hours | HTTP, Schedule, Slack | 5 |  |
| `TI-03` | Brand & Domain Squatting Monitor | Daily 08:00 | HTTP, Jira, PostgreSQL, Schedule, Slack | 7 |  |
| `TI-04` | Threat Actor TTP Profiler (MITRE ATT&CK) | Weekly Monday 07:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |
| `TI-05` | Geopolitical Threat Level Adaptor | Weekly Monday 06:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |

## Security awareness

| ID | Workflow | Trigger | Integrations | Nodes | |
|---|---|---|---|---|---|
| `AWR-01` | Phishing Simulation Results Tracker | Weekly Monday 09:00 | HTTP, PostgreSQL, Schedule, Slack | 5 |  |
| `AWR-02` | Security Training Compliance Monitor | Daily 09:00 | HTTP, Jira, Schedule, Slack | 5 |  |
| `AWR-03` | Weekly Staff Threat Digest Emailer | Friday 16:00 | HTTP, PostgreSQL, Schedule, Slack | 6 |  |
| `AWR-04` | Password Policy Violation Alerter | Password Violation Event | HTTP, PostgreSQL, Slack, Webhook | 5 |  |
| `AWR-05` | Security Champion Leaderboard | Friday 17:00 | PostgreSQL, Schedule, Slack | 5 |  |
