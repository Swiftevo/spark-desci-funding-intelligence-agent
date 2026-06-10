# Project Proposal: Spark DeSci Funding Intelligence Agent

## Problem

DeSci funding rounds require human reviewers to evaluate many project proposals. Each proposal contains claims about scientific novelty, social impact, technical progress, and funding readiness. Reviewers must:

- Verify whether claims are supported by evidence
- Identify whether similar academic or ecosystem work already exists
- Compare proposals within the same funding round
- Separate verifiable claims from aspirational claims
- Detect missing evidence and reviewer questions

Current AI tools can summarize proposals, but summarization does not solve the real reviewer workload: multi-step evidence checking, domain context, and cross-project comparison.

## Solution

Spark DeSci Funding Intelligence Agent uses GLM-5.1 as a long-horizon reasoning engine that decomposes funding review into multiple tool-based steps:

1. **Project retrieval** - fetch the full proposal from the Spark DeSci 49-project dataset
2. **Related project search** - find similar projects in the same round
3. **Cross-project comparison** - compare progress, evidence level, and risk profiles
4. **Academic context search** - identify field maturity, prior work, and novelty questions
5. **Structured review synthesis** - produce JSON with claims, evidence gaps, risks, and reviewer questions
6. **Reviewer brief generation** - convert structured review JSON into human-readable Markdown

The agent does not make funding decisions. It reduces reviewer workload while preserving human oversight.

## Long-Horizon Task Fit

This is not a single-prompt proposal summarizer. The GLM-5.1 agent loop demonstrates:

- Autonomous task decomposition
- Multi-step tool calling
- Iterative search and comparison
- Evidence-grounded synthesis
- Execution traces that show how the review was produced

Example execution trace:

```text
Turn 1: get_project_detail -> full proposal retrieved
Turn 2: search_projects x2 -> related projects found
Turn 3: compare_projects + search_academic_context -> comparison and academic context questions
Turn 4: final structured review
```

## Web3 Value

- DeSci funding is a Web3 governance and public goods funding problem.
- The Spark DeSci 49-project dataset is public, open, and machine-readable.
- The agent makes review support more transparent by saving tool-call traces.
- Future versions can add Gitcoin grant data, on-chain donation records, and cross-round funding memory.

## Technical Architecture

```text
User input: project ID
|
GLM-5.1 agent loop
|-- search_projects(query, top)
|-- get_project_detail(project_id)
|-- compare_projects(project_ids)
|-- search_academic_context(query)      # Semantic Scholar API; AMiner planned
|
Structured review JSON
|
generate-reviewer-brief.ps1
|
Reviewer brief Markdown
```

All current tools are read-only. The system does not modify project data and does not perform on-chain transactions.

## Current Status

| Component | Status |
|-----------|--------|
| GLM-5.1 agent loop with function calling | Working |
| Spark DeSci 49-project search and retrieval | Working |
| Cross-project comparison | Working |
| Batch review runner | Working, with partial-run error reporting |
| Retry mechanism for API failures | Working |
| Token optimization | Working |
| Reviewer brief generation | Working via `scripts/generate-reviewer-brief.ps1` |
| Six reviewer brief artifacts | Included in `docs/reviewer-briefs/` |
| Academic context real API | Semantic Scholar live; AMiner planned |
| Cross-round funding memory | Post-hackathon |

## Academic Context Source And Limitation

The current academic context tool uses Semantic Scholar API metadata.

Important limitation:

```text
Academic context returned by the tool is real Semantic Scholar metadata.
Semantic Scholar coverage is not exhaustive and does not prove a project claim.
GLM-5.1 analysis based on retrieved literature still requires human review.
The next step is adding AMiner retrieval when access is available.
```

This limitation is documented in `README.md`, `DEMO_REMARKS.md`, and `SAFETY_COST_BOUNDARIES.md`.

## Team

Solo builder. Background: Web3, DeSci, and data layer design.

## Next Steps After Hackathon

1. Integrate AMiner API when access is available
2. Import Gitcoin grant data for cross-round funding memory
3. Add a lightweight reviewer UI
