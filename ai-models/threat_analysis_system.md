# Cyber Constellation — AI Prompt Library v1.2
## Templates for AI-01 | claude-opus-4-5 Enrichment Layer

---

### MASTER SYSTEM PROMPT

```
You are a senior threat analyst in a SOC. Analyze structured security alert data.
Output ONLY valid JSON — no markdown, no text outside JSON.
Be specific, not generic. Confidence scores must be honest.
Never recommend irreversible actions without verification caveats.
```

---

### ALERT ANALYSIS (AI-01 primary prompt)

```json
{
  "model": "claude-opus-4-5",
  "max_tokens": 1500,
  "messages": [{
    "role": "user",
    "content": "Analyze this alert. Return ONLY JSON:\n\n{{ALERT_JSON}}\n\n{\"threat_narrative\":\"2-3 specific sentences\",\"kill_chain_stage\":\"Reconnaissance|Weaponization|Delivery|Exploitation|Installation|C2|Actions on Objectives|Unknown\",\"mitre_techniques\":[{\"id\":\"T1234\",\"name\":\"string\",\"confidence\":\"High|Medium|Low\"}],\"threat_actor_profile\":\"string\",\"blast_radius\":\"string\",\"immediate_actions\":[\"string\"],\"investigation_queries\":[\"SIEM query\"],\"false_positive_indicators\":[\"string\"],\"analyst_verdict_hint\":\"true_positive|false_positive|needs_investigation\",\"urgency\":\"Immediate|Urgent|Normal|Low\",\"confidence_in_analysis\":0}"
  }]
}
```

---

### DAILY INTEL BRIEF (TI-01)

```
Write a 250-word max daily threat brief. 3 sections:
## THREAT OF THE DAY (1-2 sentences)
## NEW EXPLOITABLE CVEs (bullets, flag EPSS >20% as ACTIVELY EXPLOITED)
## ONE THING TO CHECK TODAY (10-minute analyst action)

Data: {{INTEL_JSON}}
```

---

### CORRELATION NARRATIVE (ORCH-03)

```json
{"messages":[{"role":"user","content":"3-sentence incident narrative for this correlation. Return JSON: {\"narrative\":\"string\",\"severity_justification\":\"string\",\"recommended_escalation\":\"string\"}\n\n{{CORRELATION_JSON}}"}]}
```

---

### THREAT HUNT HYPOTHESES (BT-06)

```json
{"messages":[{"role":"user","content":"Generate 3 hunt hypotheses. Return JSON:\n{\"hypotheses\":[{\"id\":\"H1\",\"hypothesis\":\"We believe X is doing Y because Z\",\"mitre\":\"T1234\",\"data_sources\":[\"string\"],\"hunt_query\":\"SIEM query\",\"priority\":\"High|Medium|Low\"}]}\n\nEnvironment:{{ENV}}\nIntel:{{INTEL}}"}]}
```

---

### POST-INCIDENT SUMMARY

```json
{"messages":[{"role":"user","content":"Write post-incident wiki entry. Return JSON:\n{\"executive_summary\":\"2 sentences\",\"technical_summary\":\"string\",\"timeline\":[{\"time\":\"HH:MM\",\"event\":\"string\"}],\"root_cause\":\"string\",\"detection_gaps\":[\"string\"],\"improvements\":[\"string\"],\"lessons_learned\":[\"string\"]}\n\nIncident: {{INCIDENT_JSON}}"}]}
```

---

### CALIBRATION NOTES
- `claude-opus-4-5` for all production analysis (highest accuracy)
- `claude-haiku-4-5` for high-volume pre-filtering (cost optimization, run first)
- Always parse with try/catch — strip ```json fences before JSON.parse()
- log tokens_used to ai_enrichment_log for cost tracking
