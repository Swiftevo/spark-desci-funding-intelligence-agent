# Demo Script: Spark DeSci Funding Intelligence Agent

**Duration**: 3 minutes
**Target**: Z.AI Track - Web3 x Long-Horizon Task
**Primary Demo Project**: DSPJ-0003 (LLM Evaluators in PGF)
**Recorded demo LLM**: GLM-5.1 via OpenCode / `xixixixi/glm-5.1`

## 0. Pre-Demo Setup

Open PowerShell in the repo:

```powershell
cd "C:\Users\User\Documents\Codex\2026-06-03\files-mentioned-by-the-user-txt\work\spark-glm-review-agent"
.\scripts\import-spark-data.ps1
```

Optional, only if available:

```powershell
$env:SEMANTIC_SCHOLAR_API_KEY="your_key"
```

For the recorded video, use OpenCode with GLM-5.1 via `xixixixi/glm-5.1`. This avoids depending on the external Z.AI API balance during the live recording. The repo still includes the Z.AI API-based PowerShell agent loop for reproducibility.

## 1. Opening Narration

Say:

```text
Spark DeSci Funding Intelligence Agent uses GLM-5.1 to assist human reviewers in a DeSci funding round.

Instead of only summarizing proposals, it follows a long-horizon review workflow: retrieve project data, check public evidence links, search related projects, compare projects in the same round, check academic context through Semantic Scholar with OpenAlex and local cache fallback, and generate reviewer support.
```

## 2. Ask GLM To Inspect The Project

In OpenCode, ask:

```text
Read README.md, DEMO_SCRIPT.md, todo.md, and docs/reviewer-briefs/DSPJ-0003-reviewer-brief.md.
Summarize how this agent reviews DSPJ-0003 and explain the long-horizon workflow.
Do not edit files.
```

Show that GLM can understand the repo structure and the prepared reviewer artifact.

## 3. Show The Long-Horizon Workflow

Narrate the workflow:

```text
Project ID: DSPJ-0003
|
get_project_detail
|
fetch_web_resource
|
search_projects
|
compare_projects
|
search_academic_context using Semantic Scholar / OpenAlex / local cache fallback
|
structured review JSON
|
reviewer brief Markdown
```

Key point:

```text
The agent performs multi-step review support, not a one-shot summary.
```

## 4. Show Spark Data Retrieval

Run:

```powershell
.\scripts\get-project-detail.ps1 -ProjectId DSPJ-0003
```

Say:

```text
The project data comes from the Spark DeSci 49-project dataset.
This gives the agent real proposal data instead of a synthetic demo prompt.
```

## 5. Show Related Project Search

Run:

```powershell
.\scripts\search-projects.ps1 -Query "LLM evaluation funding proposals" -Top 5
```

Say:

```text
The agent can retrieve related projects from the same funding round for cross-project comparison.
```

## 6. Show Academic Context

Run if rate limits allow:

```powershell
.\scripts\search-semantic-scholar.ps1 -Query "LLM bias evaluation" -Limit 2
```

If it works, show:

```text
paper metadata
citation counts
field maturity
credibility questions
claim-to-literature comparison in the generated review
```

If Semantic Scholar returns a rate limit, say:

```text
Semantic Scholar is live but rate limited. The agent can fallback to OpenAlex, and if both live providers fail it uses a small local academic metadata cache as a final guardrail instead of pretending the literature check succeeded.
```

Then show the local cache fallback directly:

```powershell
.\scripts\search-academic-cache.ps1 -Query "LLM bias" -Domain "AI / Data" -Limit 2
```

Say:

```text
The local cache stores metadata only: titles, authors, citation counts, DOI/OpenAlex IDs, and OA links. It is not a full literature review, but it keeps the review workflow resilient when live APIs are unavailable.
```

Important comparison caveat:

```text
When abstracts are available, the agent can compare project claims against paper abstracts.
When only metadata is available, the agent marks the comparison as metadata-only and treats it as a reviewer cue, not validation.
```

## 6A. Show Web Evidence Check

Run:

```powershell
.\scripts\fetch-web-resource.ps1 -Url "https://github.com/psf/requests"
```

Say:

```text
The agent can inspect public evidence links at metadata level: GitHub activity, license, README presence, and code/package signals. This does not prove code quality, but it helps reviewers quickly identify whether an external evidence link is real and inspectable.
```

## 7. Show Reviewer Brief

Open the prepared artifact:

```powershell
notepad .\docs\reviewer-briefs\DSPJ-0003-reviewer-brief.md
```

Say:

```text
The reviewer brief converts agent analysis into a human-readable format: summary, claims, academic claim comparison, missing evidence, risks, and reviewer questions.
```

Important note:

```text
The checked-in reviewer briefs are demo artifacts. Current agent runs support Semantic Scholar, OpenAlex fallback, and local academic metadata cache when available.
```

## 8. Explain Current Boundaries

Say:

```text
The system does not make funding decisions.
It produces review support for human evaluators.
Semantic Scholar, OpenAlex, and local cache metadata are useful academic context, but not exhaustive validation.
AMiner integration and Gitcoin QF integrity analysis are planned next modules.
```

## 9. Closing

Say:

```text
This prototype demonstrates GLM-5.1 as a long-horizon DeSci funding review assistant.
It combines real Spark DeSci project data, tool-based retrieval, cross-project comparison, academic context from Semantic Scholar / OpenAlex fallback, and reviewer brief generation.
It also includes public web evidence checks and a local academic metadata cache for resilience during API rate limits.
```

## Optional API-Based Demo Path

If external Z.AI API quota is available, the full PowerShell agent loop can be run with:

```powershell
$env:ZAI_API_KEY="your_api_key"
.\scripts\demo.ps1 -ProjectId DSPJ-0003
```

This path calls the Z.AI API directly from `scripts/run-agent-review.ps1`. It is useful for reproducibility, but it is not required for the OpenCode / `xixixixi/glm-5.1` recorded demo.
