# Cyber Constellation — Credential Setup Guide
## Every credential needed, exact n8n field names, where to get each

---

## HOW TO ADD CREDENTIALS IN N8N

Settings → Credentials → Add Credential → search type → fill fields → Save

Use the exact **Credential ID** listed below when referencing in workflow JSONs.

---

## REQUIRED (Phase 1 won't work without these)

### POSTGRES_MAIN — PostgreSQL
**Type:** PostgreSQL  
**Fields:**
```
Host:     postgres (or localhost / your DB IP)
Port:     5432
Database: constellation
User:     constellation
Password: [from your .env POSTGRES_PASSWORD]
SSL:      Disabled (enable for production cloud DB)
```
**Used by:** Every workflow that logs to DB

---

### SLACK_MAIN — Slack API
**Type:** Slack API  
**Fields:**
```
Access Token: xoxb-... (Bot token from Slack App settings)
```
**Get it:**
1. api.slack.com/apps → Create New App → From scratch
2. OAuth & Permissions → Bot Token Scopes: `chat:write`, `chat:write.public`, `channels:manage`, `conversations.create`
3. Install to workspace → copy Bot User OAuth Token

**Channels needed:**
```
C_SOC_ALERTS      #soc-alerts
C_SOC_TRIAGE      #soc-triage
C_SOC_INCIDENTS   #soc-incidents
C_SOC_ERRORS      #soc-errors
C_DETECTION_ENG   #detection-engineering
C_IAM             #iam-security
C_CLOUD_SEC       #cloud-security
C_NETWORK_SEC     #network-security
C_ENDPOINT_SEC    #endpoint-security
C_VULN_MGMT       #vuln-management
C_THREAT_INTEL    #threat-intel
C_RED_TEAM        #red-team (private)
C_DFIR            #dfir-forensics (private)
C_APPSEC_ALERTS   #appsec-alerts
C_GRC             #grc-compliance
C_CISO            #ciso-escalations (private)
C_SOC_HANDOVER    #soc-handover
C_GENERAL         #general
C_SECURITY_AWARENESS #security-awareness
C_LEGAL_PRIVACY   #legal-privacy
```
Replace C_* placeholders in workflow JSONs with actual Slack channel IDs.  
Get channel ID: Right-click channel → View channel details → ID at bottom

---

### JIRA_MAIN — Jira API
**Type:** Jira API  
**Fields:**
```
Host:     https://yourcompany.atlassian.net
Email:    your-service-account@company.com
API Token: [from id.atlassian.com/manage-profile/security/api-tokens]
```
**Projects needed in Jira:**
```
SOC    — Security Operations Center
IAM    — Identity & Access Management
PATCH  — Patch Management
GRC    — Governance, Risk, Compliance
CLOUD  — Cloud Security
NETWORK — Network Security
DLP    — Data Loss Prevention
DFIR   — Digital Forensics
APPSEC — Application Security
REDTEAM — Red Team (restricted)
HR     — Human Resources
TI     — Threat Intelligence
```

---

### ANTHROPIC_API — Anthropic (Claude)
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  x-api-key
Value: sk-ant-api03-...
```
**Get it:** console.anthropic.com → API Keys → Create Key  
**Used by:** AI-01, TI-01, BT-06, AWR-03, VM-06, TI-04

---

## IMPORTANT — PHASE 1

### OKTA_API — Okta
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: SSWS YOUR_OKTA_API_TOKEN
```
**Get it:** Okta Admin Console → Security → API → Tokens → Create Token

### WAZUH_API — Wazuh SIEM
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer YOUR_WAZUH_JWT_TOKEN
```
**Get it:**
```bash
curl -u admin:password -k https://your-wazuh:55000/security/user/authenticate -X POST
```

### NVD_API — NVD CVE Database
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  apiKey
Value: [your NVD API key]
```
**Get it:** nvd.nist.gov/developers/request-an-api-key (free, takes ~1 day)

### VT_API — VirusTotal
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  x-apikey
Value: [your VT API key]
```
**Get it:** virustotal.com/gui/my-apikey (free tier: 500 lookups/day)

---

## PHASE 2

### GITHUB_API — GitHub
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer ghp_yourPersonalAccessToken
```
**Get it:** GitHub → Settings → Developer settings → Personal access tokens → Fine-grained  
**Scopes needed:** `repo`, `read:org`, `pull_requests:write`, `statuses:write`

### AWS_MAIN — AWS
**Type:** AWS  
**Fields:**
```
Access Key ID:     AKIA...
Secret Access Key: ...
Region:            ap-south-1
```

### AZURE_API — Azure
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [Azure AD access token]
```
**Get it:** Azure Portal → App registrations → New registration → Certificates & secrets

### CROWDSTRIKE_API — CrowdStrike EDR
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [CrowdStrike OAuth2 token]
```
**Get it:** CrowdStrike Falcon console → API Clients and Keys

### FIREWALL_API — Firewall (Palo Alto / FortiGate / pfSense)
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [your firewall REST API token]
```
Adapt URL in NET-01/NET-02 to match your firewall vendor's API format.

### NESSUS_API — Nessus
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  X-ApiKeys
Value: accessKey=XXXX; secretKey=YYYY
```
**Get it:** Nessus → Settings → My Account → API Keys

### SHODAN_API — Shodan
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  key (query param, not header)
Value: [your Shodan API key]
```
**Get it:** account.shodan.io (free tier: limited)

### HIBP_API — HaveIBeenPwned
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  hibp-api-key
Value: [your HIBP API key]
```
**Get it:** haveibeenpwned.com/API/Key (paid, ~£3.50/month)

### OTX_API — AlienVault OTX
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  X-OTX-API-KEY
Value: [your OTX API key]
```
**Get it:** otx.alienvault.com → Account settings → OTX Key (free)

### SEMGREP_API — Semgrep
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [your Semgrep token]
```
**Get it:** semgrep.dev → Settings → Tokens

### SNYK_API — Snyk
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Token [your Snyk token]
```
**Get it:** app.snyk.io → Account settings → Auth token

---

## PHASE 3

### ANYRUN_API — Any.run Sandbox
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: API-Key [your Any.run key]
```
**Get it:** app.any.run → Profile → API key (free tier: 5 concurrent)

### GOPHISH_API — GoPhish
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [GoPhish API key from web UI]
```
**Get it:** GoPhish web UI → Settings → API Keys

### MSRC_API — Microsoft Security Response Center
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  api-key
Value: [MSRC API key]
```
**Get it:** msrc.microsoft.com/blog/2015/05/22/new-msrc-portal-api/ (free)

### KB4_API — KnowBe4
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [KnowBe4 API key]
```
**Get it:** KnowBe4 Account Settings → API → Create API Key

### MDM_API — Mobile Device Management (Jamf / Intune)
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [your MDM API token]
```
Adapt URL in EP-02 to your MDM vendor's API.

### GRAPH_API — Microsoft Graph (for AD/Entra)
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [Microsoft Graph access token]
```
**Get it:** Azure AD → App registrations → API permissions → Microsoft Graph

### URLSCAN_API — URLScan.io
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  API-Key
Value: [your urlscan.io API key]
```
**Get it:** urlscan.io → Profile → API Key (free tier: 5000/day)

### HUNTER_API — Hunter.io
**Type:** Query Parameter (embed in URL)  
**Fields:** Embed `api_key={{ $credentials.hunterApi.apiKey }}` in URL  
**Get it:** hunter.io → API → API key (free: 25 searches/month)

---

## QUICK SETUP CHECKLIST

### Phase 1 (must have before enabling any workflow)
- [ ] POSTGRES_MAIN
- [ ] SLACK_MAIN + all channels created
- [ ] JIRA_MAIN + all projects created
- [ ] ANTHROPIC_API (for AI-01, TI-01)
- [ ] OKTA_API
- [ ] WAZUH_API
- [ ] NVD_API
- [ ] VT_API
- [ ] OTX_API

### Phase 2 (before enabling phase 2 workflows)
- [ ] GITHUB_API
- [ ] AWS_MAIN
- [ ] CROWDSTRIKE_API
- [ ] FIREWALL_API
- [ ] NESSUS_API or QUALYS_API
- [ ] SHODAN_API
- [ ] HIBP_API
- [ ] SEMGREP_API
- [ ] SNYK_API
- [ ] AZURE_API

### Phase 3 (before enabling phase 3 workflows)
- [ ] ANYRUN_API
- [ ] GOPHISH_API
- [ ] KB4_API
- [ ] MDM_API
- [ ] MSRC_API
- [ ] GRAPH_API
- [ ] URLSCAN_API
- [ ] HUNTER_API

---

## SECURITY NOTES

1. **Never** store credentials in workflow JSON — always use n8n credential vault
2. **Rotate** all credentials every 90 days — set calendar reminders
3. **Least privilege** — create service accounts with minimum required permissions
4. **Audit** n8n credential access logs monthly
5. **Backup** n8n encryption key — losing it means losing all stored credentials
   ```bash
   # N8N_ENCRYPTION_KEY from your .env — store in a password manager
   grep N8N_ENCRYPTION_KEY /path/to/.env
   ```

---

## ADDITIONAL CREDENTIALS (referenced in workflows)

### AD_API — Active Directory REST API
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [AD management API token]
```
**Note:** This wraps your AD/Entra management endpoint. If using Microsoft Graph, use GRAPH_API instead.  
For on-premise AD, deploy a lightweight REST wrapper (e.g. adapi.yourdomain.com) or use LDAP directly via n8n's LDAP node.

---

### H1_API — HackerOne API
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Basic [base64 of api_id:api_key]
```
**Get it:** hackerone.com → Settings → API Tokens → Create API Token  
Program must be active on HackerOne to use the API.

---

### WIZ_API — Wiz Cloud Security
**Type:** HTTP Header Auth  
**Fields:**
```
Name:  Authorization
Value: Bearer [Wiz access token]
```
**Get it:**
1. Wiz portal → Settings → Service Accounts → Create
2. Generate access token with `read:issues` scope
3. Token endpoint: https://auth.app.wiz.io/oauth/token
```bash
curl -X POST https://auth.app.wiz.io/oauth/token \
  -d 'grant_type=client_credentials&client_id=YOUR_ID&client_secret=YOUR_SECRET&audience=wiz-api'
```
