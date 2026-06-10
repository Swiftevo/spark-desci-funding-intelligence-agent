# Spark DeSci Funding Intelligence Agent

Use GLM-5.1 to assist human reviewers in a DeSci funding round by producing structured review support from Spark DeSci project data.

GitHub repo:

```text
https://github.com/Swiftevo/spark-desci-funding-intelligence-agent
```

This project participates in the **Z.AI Track - Web3 x Long-Horizon Task** of the AI x Web3 Agentic Builders Hackathon.

## Hackathon Track

Core evaluation signals:

- GLM-5.1 drives long-horizon task execution
- The agent uses planning and tool calling, not one-shot summarization
- The workflow addresses a real DeSci funding review pain point
- The demo is runnable from PowerShell

## Architecture

### Current Scripted Pipeline

```text
Spark 49-project CSV
|
import-spark-data.ps1 -> data/projects.json
|
search-projects.ps1 / get-project-detail.ps1
|
run-dummy-review.ps1
|
search-semantic-scholar.ps1
|
reviewer brief
```

### Current GLM-5.1 Agent Loop

```text
User: Review project DSPJ-0003
|
GLM-5.1 agent loop
|-- get_project_detail
|-- search_projects
|-- compare_projects
|-- search_academic_context (Semantic Scholar API)
|
Structured review JSON
|
generate-reviewer-brief.ps1
|
Reviewer brief Markdown
```

Tools available to the agent:

| Tool | Purpose |
|------|---------|
| `search_projects` | Search the 49-project Spark dataset |
| `get_project_detail` | Get full project details by ID |
| `compare_projects` | Compare the target with related projects |
| `search_academic_context` | Search Semantic Scholar API for academic literature context |

## Academic Context Source

The `search_academic_context` tool now uses **Semantic Scholar API** for real academic literature retrieval.

Key features:
- Paper search with citation counts and field analysis
- Field maturity assessment (emerging/active/established)
- Credibility questions based on retrieved literature
- Open access PDF links when available

Demo caveats:

```text
1. Semantic Scholar API rate limits may apply. If available, set `SEMANTIC_SCHOLAR_API_KEY` for more stable access.
2. Not all projects will have extensive literature — some topics may have limited results.
3. The next step is adding AMiner API when access is obtained.
4. Agent analysis based on retrieved literature is real, but still limited to Semantic Scholar's coverage.
```

Spark project retrieval, GLM-5.1 tool calling, Spark cross-project comparison, and Semantic Scholar academic context are all live.

## Quick Start

Set your Z.AI API key:

```powershell
$env:ZAI_API_KEY="your_api_key"
# Optional, if you have one:
$env:SEMANTIC_SCHOLAR_API_KEY="your_semantic_scholar_key"
```

### One-Click Demo

Run the complete demo (single project + optional batch):

```powershell
.\scripts\demo.ps1 -ProjectId DSPJ-0003
```

With batch review:

```powershell
.\scripts\demo.ps1 -ProjectId DSPJ-0003 -BatchSize 5
```

### Step-by-Step

Import Spark DeSci projects:

```powershell
.\scripts\import-spark-data.ps1
```

Search and inspect projects:

```powershell
.\scripts\search-projects.ps1 -Query "AI funding evaluator" -Top 5
.\scripts\get-project-detail.ps1 -ProjectId DSPJ-0030
```

Run the GLM-5.1 agent loop:

```powershell
.\scripts\run-agent-review.ps1 -ProjectId DSPJ-0003 -MaxRetries 2
```

Generate a reviewer brief:

```powershell
.\scripts\generate-reviewer-brief.ps1 -ProjectId DSPJ-0003
```

Run batch agent reviews:

```powershell
.\scripts\run-batch-review.ps1 -SampleSize 5
```

Test GLM-5.1 connection:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-glm.ps1
```

## Output Structure

Generated local outputs are written to:

```text
outputs/
```

Tracked demo reviewer brief artifacts are included in:

```text
docs/reviewer-briefs/
```

Current tracked demo briefs:

```text
DSPJ-0003-reviewer-brief.md
DSPJ-0006-reviewer-brief.md
DSPJ-0007-reviewer-brief.md
DSPJ-0018-reviewer-brief.md
DSPJ-0020-reviewer-brief.md
DSPJ-0038-reviewer-brief.md
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
| `run-dummy-review.ps1` | Keep as no-API fallback |
| `run-glm-project-review.ps1` | Single-call GLM baseline |
| `run-agent-review.ps1` | Main GLM-5.1 function-calling agent loop |
| `generate-reviewer-brief.ps1` | Convert agent review JSON into Markdown reviewer brief |
| `search-semantic-scholar.ps1` | Academic context search via Semantic Scholar API |

## Roadmap

See [todo.md](./todo.md) for milestones and progress.

## Submission Docs

- [PROPOSAL.md](./PROPOSAL.md)
- [DEMO_SCRIPT.md](./DEMO_SCRIPT.md) - 3-minute demo walkthrough
- [SAFETY_COST_BOUNDARIES.md](./SAFETY_COST_BOUNDARIES.md)
- [DEMO_REMARKS.md](./DEMO_REMARKS.md)
- [HACKATHON_ALIGNMENT.md](./HACKATHON_ALIGNMENT.md)
- [DELIVERY_CHECKLIST.md](./DELIVERY_CHECKLIST.md)

## Data Sources

- [desci-funding-data-layer](https://github.com/Swiftevo/desci-funding-data-layer) - 49 Spark DeSci projects
- [Z.AI GLM-5.1 API](https://docs.z.ai/api-reference/introduction) - core LLM
- [Semantic Scholar API](https://api.semanticscholar.org/) - academic context (live)
- [AMiner API](https://www.aminer.cn/) - academic context planned, pending API access
