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

Instead of only summarizing proposals, it follows a long-horizon review workflow: retrieve project data, search related projects, compare projects in the same round, check academic context through Semantic Scholar, and generate reviewer support.
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
search_projects
|
compare_projects
|
search_academic_context using Semantic Scholar
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

## 6. Show Semantic Scholar Context

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
```

If Semantic Scholar returns a rate limit, say:

```text
Semantic Scholar is live but rate limited. The script handles this as a needs-verification signal instead of pretending the literature check succeeded.
```

## 7. Show Reviewer Brief

Open the prepared artifact:

```powershell
notepad .\docs\reviewer-briefs\DSPJ-0003-reviewer-brief.md
```

Say:

```text
The reviewer brief converts agent analysis into a human-readable format: summary, claims, missing evidence, risks, and reviewer questions.
```

Important note:

```text
The checked-in reviewer briefs are archived demo artifacts generated before Semantic Scholar integration.
New runs use Semantic Scholar metadata when available.
```

## 8. Explain Current Boundaries

Say:

```text
The system does not make funding decisions.
It produces review support for human evaluators.
Semantic Scholar metadata is useful academic context, but not exhaustive validation.
AMiner integration and Gitcoin QF integrity analysis are planned next modules.
```

## 9. Closing

Say:

```text
This prototype demonstrates GLM-5.1 as a long-horizon DeSci funding review assistant.
It combines real Spark DeSci project data, tool-based retrieval, cross-project comparison, Semantic Scholar academic context, and reviewer brief generation.
```

## Optional API-Based Demo Path

If external Z.AI API quota is available, the full PowerShell agent loop can be run with:

```powershell
$env:ZAI_API_KEY="your_api_key"
.\scripts\demo.ps1 -ProjectId DSPJ-0003
```

This path calls the Z.AI API directly from `scripts/run-agent-review.ps1`. It is useful for reproducibility, but it is not required for the OpenCode / `xixixixi/glm-5.1` recorded demo.
