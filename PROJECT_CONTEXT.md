# Project Context

This file preserves key decisions, architecture, and context so any agent or developer can pick up the project without starting over.

## Project Identity

- **Name**: Spark DeSci Funding Intelligence Agent
- **Hackathon**: AI x Web3 Agentic Builders Hackathon (2026-06-01 ~ 2026-06-13)
- **Track**: Z.AI Track | Web3 x Long-Horizon Task
- **Team**: Solo (1 person)
- **LLM**: GLM-5.1 via Z.AI API (`https://api.z.ai/api/paas/v4/chat/completions`)

## Problem Statement

DeSci funding rounds have human reviewers who must evaluate many project proposals. Review workload is high. This agent reduces reviewer workload by producing structured, evidence-aware review support — not making final funding decisions.

## Current Status (What Is Already Done)

| Item | Status | Notes |
|------|--------|-------|
| Data import (49 projects CSV → JSON) | ✅ Done | `data/projects.json` exists |
| Project search (weighted term matching) | ✅ Done | `scripts/search-projects.ps1` |
| Project detail lookup | ✅ Done | `scripts/get-project-detail.ps1` |
| Dummy review (rule-based) | ✅ Done | `scripts/run-dummy-review.ps1` |
| Dummy AMiner context | ✅ Done | `scripts/search-aminer-context.ps1` (placeholder data) |
| Dummy full workflow | ✅ Done | `scripts/run-agent-workflow.ps1` (scripted pipeline) |
| GLM-5.1 single review | ✅ Done | `scripts/run-glm-review.ps1`, `scripts/run-glm-project-review.ps1` |
| GLM-5.1 connection test | ✅ Done | `scripts/test-glm.ps1` |
| Agent loop with function calling | ❌ Not started | M1 — next to build |
| Batch review | ❌ Not started | M2 |
| Cross-project comparison | ❌ Not started | M3 |
| Real academic context (Semantic Scholar) | ❌ Not started | Deferred |
| Real academic context (AMiner) | ❌ Not started | Waiting for API access |

## Scripts Reference

| Script | Purpose | Input | Output |
|--------|---------|-------|--------|
| `import-spark-data.ps1` | Import 49-project CSV into JSON | CSV path (default: `../desci-funding-data-layer/exports/public/desci_funding_data_layer_latest.csv`) | `data/projects.json` |
| `search-projects.ps1` | Search projects with weighted term matching | `-Query`, `-Top` | JSON array of matched projects with scores |
| `get-project-detail.ps1` | Get full project detail by ID | `-ProjectId` (e.g. DSPJ-0030) | Full project JSON |
| `run-dummy-review.ps1` | Rule-based review (no LLM) | `-ProjectId`, `-ProjectsPath`, `-OutPath` | Review JSON |
| `search-aminer-context.ps1` | Dummy academic context (placeholder) | `-Query`, `-OutPath` | AMiner context JSON (fake data) |
| `run-agent-workflow.ps1` | Full scripted workflow (dummy review → dummy AMiner → brief) | `-ProjectId` | Review JSON + AMiner JSON + Brief MD |
| `run-glm-review.ps1` | Single GLM-5.1 review on sample project | `-ProjectPath`, `-Model`, `-Mock` | `review-output.json` |
| `run-glm-project-review.ps1` | Single GLM-5.1 review on any project by ID | `-ProjectId`, `-Model` | `outputs/{ID}-glm-review.json` |
| `test-glm.ps1` | Test GLM-5.1 API connection | `-Model`, `-Prompt` | Console output |

## Next Steps (Prioritized)

1. **M1**: Build `run-agent-review.ps1` — GLM function calling agent loop (CRITICAL)
2. **M2**: Build `run-batch-review.ps1` — batch 5 random projects
3. **M3**: Optimize prompts, add cross-project comparison to reviewer brief
4. **M4**: Demo prep, README for submission, execution trace cleanup

## Data

- **49 Spark DeSci projects** from [desci-funding-data-layer](https://github.com/Swiftevo/desci-funding-data-layer)
- Imported via `scripts/import-spark-data.ps1` → `data/projects.json`
- Each project has: project_entity_id, project_name, domain, what_are_you_making, impact, progress, evidence_level, risk_flag, github_path, raw_text, fundability_score, etc.
- For batch review: randomly sample 5 projects (to save tokens)

## Architecture Decision

### Chosen: GLM Function Calling Agent Loop

GLM-5.1 must demonstrate **autonomous** long-horizon task capability for the hackathon evaluation. The scripted PowerShell pipeline (v0) cannot demonstrate this.

In the agent loop:
1. System prompt defines the agent role and available tools
2. GLM-5.1 receives the review request and autonomously decides which tools to call
3. Each tool call result is fed back into the conversation
4. GLM-5.1 iterates until it produces the final structured review
5. The full execution trace (think → tool call → result → think) serves as demo evidence

### Tools

| Tool | Input | Output | Implementation |
|------|-------|--------|----------------|
| `search_projects` | query, top | ranked project list | Reuse `search-projects.ps1` logic |
| `get_project_detail` | project_id | full project JSON | Reuse `get-project-detail.ps1` logic |
| `compare_projects` | project_ids | comparison analysis | New, inline in agent script |
| `search_academic_context` | query | academic literature results | Semantic Scholar later, dummy for now |
| `generate_reviewer_brief` | review_json | markdown brief | New, inline in agent script |

### Output Schema

Each review produces:

```json
{
  "mode": "agent-glm-5.1",
  "project_entity_id": "DSPJ-XXXX",
  "executive_summary": "...",
  "extracted_claims": ["..."],
  "milestone_assessment": ["..."],
  "evidence_found": ["..."],
  "missing_evidence": ["..."],
  "academic_context_queries_for_aminer": ["..."],
  "academic_context_results": [...],
  "cross_project_comparison": "...",
  "funding_memory_observations": ["..."],
  "risk_flags": [{"risk": "...", "severity": "low|medium|high", "reason": "..."}],
  "suggested_reviewer_questions": ["..."],
  "human_review_support_status": "ready_for_review | needs_more_evidence | high_risk_claims"
}
```

## Key Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-07 | Use GLM function calling agent loop | Hackathon requires demonstrating long-horizon autonomous capability; scripted pipeline cannot show this |
| 2026-06-07 | Batch review uses 5 random projects, not all 49 | Save API tokens; 5 is sufficient for demo |
| 2026-06-07 | Semantic Scholar as interim academic context source | No AMiner API yet; Semantic Scholar is free and keyless; will swap to AMiner when API is obtained |
| 2026-06-07 | Academic context must be labeled as placeholder until real retrieval is integrated | GLM-5.1 analysis based on placeholder context is not real literature support |
| 2026-06-07 | Funding memory = same Spark round only | No cross-round data yet; will extend to Gitcoin grants post-hackathon |
| 2026-06-07 | Keep PowerShell for scripts | Consistency with existing codebase; agent core uses same Z.AI API patterns |

## Hackathon Submission Requirements

- [ ] GitHub Repo with README (background, install, run, architecture, API usage)
- [ ] Demo video (3-5 min)
- [ ] Project documentation / proposal
- [ ] Execution trace showing agent's autonomous task decomposition, tool calls, iteration
- [ ] Web3 proof / on-chain evidence (DeSci funding is Web3-adjacent)
- [ ] Safety, cost, and permission boundary documentation

## Evaluation Criteria (Z.AI Track)

1. Track match: Web3 x Long-Horizon Task, not just Q&A
2. GLM-5.1 usage criticality: core long-horizon task driven by GLM-5.1
3. Task complexity & closure: requirement → plan → execute → verify → repair → deliver
4. Long-horizon stability: goal consistency across multi-step execution
5. Web3 value: solves real Web3 problem
6. Demo & reproducibility: stable demo, agent process visible
7. Safety, cost, permission boundaries: documented

## Startup Prompt for OpenCode / GLM

When resuming this project, feed the following prompt to the agent:

```
You are working on the Spark DeSci Funding Intelligence Agent, a hackathon project for the Z.AI Track (Web3 x Long-Horizon Task) at the AI x Web3 Agentic Builders Hackathon (deadline 2026-06-13).

Read these files first:
1. project_context.md — full project context, decisions, architecture, and current status
2. todo.md — milestones and progress
3. docs/2026-06-07.md — latest development diary

Current priority: M1 — Build run-agent-review.ps1, the GLM-5.1 function calling agent loop.

The agent loop must:
- Use GLM-5.1 via Z.AI API (https://api.z.ai/api/paas/v4/chat/completions)
- Define tools as function schemas: search_projects, get_project_detail, compare_projects, search_academic_context, generate_reviewer_brief
- Let GLM-5.1 autonomously decide which tools to call and in what order
- Feed tool execution results back into the conversation
- Continue until GLM-5.1 produces a final structured review JSON
- Output an execution trace showing the agent's autonomous decision process
- Also output a reviewer brief in Markdown

Key constraints:
- PowerShell scripts only (consistent with existing codebase)
- Environment variable ZAI_API_KEY for API access
- Projects data is in data/projects.json
- Test with 1-2 projects first, then expand to batch of 5 random projects
- API supports response_format json_object and thinking mode

Check the Z.AI API docs at https://docs.z.ai/api-reference/introduction for function calling / tool use format before implementing.
```

## External Resources

- Z.AI API docs: https://docs.z.ai/api-reference/introduction
- Z.AI developer docs: https://docs.z.ai/devpack/overview
- GLM-5.1 tech report: https://z.ai/blog/glm-5.1
- Semantic Scholar API: https://api.semanticscholar.org/
- AMiner: https://www.aminer.cn/ (pending API access)
