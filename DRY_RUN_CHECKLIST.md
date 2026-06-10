# Dry Run Checklist

Use this checklist before recording the hackathon demo.

## Environment

```powershell
cd "C:\Users\User\Documents\Codex\2026-06-03\files-mentioned-by-the-user-txt\work\spark-glm-review-agent"
git status --short
```

Expected:

```text
Only known local temporary files should appear.
No API keys or output files should be staged accidentally.
```

Optional API checks:

```powershell
if ($env:ZAI_API_KEY) { "ZAI key visible" } else { "ZAI key missing" }
if ($env:OPENALEX_API_KEY) { "OpenAlex key visible" } else { "OpenAlex key missing" }
if ($env:SEMANTIC_SCHOLAR_API_KEY) { "Semantic Scholar key visible" } else { "Semantic Scholar key missing" }
```

## Core Data

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\import-spark-data.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\get-project-detail.ps1 -ProjectId DSPJ-0003
powershell -ExecutionPolicy Bypass -File .\scripts\search-projects.ps1 -Query "LLM evaluation funding proposals" -Top 5
```

Expected:

```text
DSPJ-0003 is retrieved.
Related Spark projects are returned.
```

## Web Evidence Check

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-web-resource.ps1 -Url "https://github.com/psf/requests"
```

Expected:

```text
status: success
resource_type: github
stars / forks / pushed_at / license returned
README and code/package signals returned
```

Safety check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-web-resource.ps1 -Url "file:///C:/Windows/win.ini"
```

Expected:

```text
status: error
Only absolute http/https URLs are allowed.
```

## Academic Context

Primary live academic API, if rate limits allow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\search-semantic-scholar.ps1 -Query "LLM bias evaluation" -Limit 2
```

OpenAlex fallback check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\search-openalex.ps1 -Query "LLM bias evaluation" -Limit 3
```

Local cache final fallback check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\search-academic-cache.ps1 -Query "LLM bias" -Domain "AI / Data" -Limit 2
powershell -ExecutionPolicy Bypass -File .\scripts\search-academic-cache.ps1 -Query "governance DAO" -Domain "Governance / DAO" -Limit 3
```

Expected:

```text
Local cache returns metadata records only.
Do not describe local cache as full-text validation.
```

## Agent Demo Paths

Recorded OpenCode path:

```text
Use OpenCode with GLM-5.1 via xixixixi/glm-5.1.
Ask it to read README.md, DEMO_SCRIPT.md, todo.md, and a reviewer brief.
Ask it to explain the long-horizon workflow without editing files.
```

Optional direct Z.AI API path, only if quota is available:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-agent-review.ps1 -ProjectId DSPJ-0003
```

Expected:

```text
Tool trace shows multi-step review.
Output JSON and trace are written under outputs/.
```

## Reviewer Brief

```powershell
notepad .\docs\reviewer-briefs\DSPJ-0003-reviewer-brief.md
```

Mention:

```text
Checked-in reviewer briefs are archived demo artifacts.
New runs use Semantic Scholar / OpenAlex / local cache metadata when available.
Human reviewers remain final decision-makers.
```

## Final Pre-Recording Checks

```powershell
git status --short
rg -n "sk-|Bearer [A-Za-z0-9]|api_key=[A-Za-z0-9]|OPENALEX_API_KEY=|ZAI_API_KEY=" .
```

Expected:

```text
No real secrets.
Only placeholder environment variable examples.
```
