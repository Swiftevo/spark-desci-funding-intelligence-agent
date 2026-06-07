# Spark DeSci Funding Intelligence Agent

Use GLM-5.1 to assist human reviewers in a DeSci funding round by producing a structured review brief from Spark DeSci project data.

This project participates in the **Z.AI Track | Web3 x Long-Horizon Task** of the AI x Web3 Agentic Builders Hackathon (2026-06-01 ~ 2026-06-13).

## Hackathon Track

**Z.AI Track — Web3 x Long-Horizon Task**

Core evaluation criteria:

- GLM-5.1 drives long-horizon tasks with autonomous planning, tool calling, and self-correction
- Agent decomposes complex tasks into multi-step plans and iterates to completion
- Web3 value: solves real problems in DeSci funding review
- Demo must be runnable, not PPT or concept

## Architecture

### Current (v0 — Scripted Pipeline)

```text
Spark 49-project CSV
  -> import-spark-data.ps1 -> projects.json
  -> search-projects.ps1 / get-project-detail.ps1
  -> run-dummy-review.ps1 (rule-based, no LLM)
  -> search-aminer-context.ps1 (dummy adapter)
  -> reviewer-brief.md
```

Also has `run-glm-review.ps1` / `run-glm-project-review.ps1` for single-call GLM-5.1 reviews.

### Target (v1 — Agent Loop with Function Calling)

```text
User: "Review project DSPJ-0003"
  |
  v
GLM-5.1 Agent Loop (autonomous):
  1. Think -> call search_projects("AI funding")
  2. Think -> call get_project_detail("DSPJ-0003")
  3. Think -> call compare_projects(["DSPJ-0003", "DSPJ-0030"])
  4. Think -> call search_academic_context("LLM evaluation funding")
  5. Think -> call generate_reviewer_brief(review_json)
  6. Synthesize -> structured review JSON + reviewer brief
  |
  v
Execution trace (shows autonomous decision-making)
```

Tools available to the agent:

| Tool | Purpose |
|------|---------|
| `search_projects` | Search the 49-project dataset |
| `get_project_detail` | Get full project details by ID |
| `compare_projects` | Cross-project comparison within same domain |
| `search_academic_context` | Academic literature search (Semantic Scholar, then AMiner) |
| `generate_reviewer_brief` | Convert review JSON to human-readable Markdown |

## Quick Start

Set your Z.AI API key:

```powershell
$env:ZAI_API_KEY="your_api_key"
```

### Import Spark DeSci 49 Projects

The dataset comes from [desci-funding-data-layer](https://github.com/Swiftevo/desci-funding-data-layer).

Clone it beside this repo, then:

```powershell
.\scripts\import-spark-data.ps1
```

This writes `data/projects.json`.

### Search & Browse Projects

```powershell
.\scripts\search-projects.ps1 -Query "AI funding evaluator" -Top 5
.\scripts\get-project-detail.ps1 -ProjectId DSPJ-0030
```

### Run Dummy Workflow (No API Key Needed)

```powershell
.\scripts\run-agent-workflow.ps1 -ProjectId DSPJ-0003
```

### Run GLM-5.1 Single Review

```powershell
.\scripts\run-glm-review.ps1
.\scripts\run-glm-project-review.ps1 -ProjectId DSPJ-0003
```

### Test GLM-5.1 Connection

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-glm.ps1
```

### Mock Mode (No API Balance)

```powershell
.\scripts\run-glm-review.ps1 -Mock
```

## Output Structure

```text
outputs/
  DSPJ-0003-review.json          # Dummy review result
  DSPJ-0003-glm-review.json      # GLM-5.1 review result
  DSPJ-0003-aminer-context.json  # Academic context (dummy for now)
  DSPJ-0003-reviewer-brief.md    # Human-readable brief
```

## API Balance Note

If Z.AI returns:

```json
{"error":{"code":"1113","message":"Insufficient balance or no resource package. Please recharge."}}
```

Recharge or activate an API resource package in the Z.AI dashboard, then retry.

## Replacement Points

| Current | Target |
|---------|--------|
| `run-dummy-review.ps1` | GLM-5.1 agent loop with function calling |
| `search-aminer-context.ps1` | Semantic Scholar API, then AMiner API |

## Roadmap

See [todo.md](./todo.md) for milestones and progress.

## Data Sources

- [desci-funding-data-layer](https://github.com/Swiftevo/desci-funding-data-layer) — 49 Spark DeSci projects
- [Z.AI GLM-5.1 API](https://docs.z.ai/api-reference/introduction) — Core LLM
- [Semantic Scholar API](https://api.semanticscholar.org/) — Academic context (planned)
- [AMiner API](https://www.aminer.cn/) — Academic context (planned, pending API access)
