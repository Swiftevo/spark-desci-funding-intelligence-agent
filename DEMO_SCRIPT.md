# Demo Script: Spark DeSci Funding Intelligence Agent

**Duration**: 3 minutes
**Target**: Z.AI Track - Web3 x Long-Horizon Task
**Primary Demo Project**: DSPJ-0003 (LLM Evaluators in PGF)

---

## 0. Setup (Pre-demo, 30 seconds)

```powershell
# Set API key
$env:ZAI_API_KEY="your_api_key"

# Import Spark DeSci project data
.\scripts\import-spark-data.ps1
```

---

## 1. Introduction (20 seconds)

> "Spark DeSci Funding Intelligence Agent uses GLM-5.1 to assist human reviewers in a DeSci funding round by producing structured review support from 49 Spark DeSci project proposals. This demo shows GLM-5.1's long-horizon task execution through autonomous tool calling."

---

## 2. Single Project Review Demo (90 seconds)

### 2.1 Run Agent Review

```powershell
.\scripts\run-agent-review.ps1 -ProjectId DSPJ-0003
```

### 2.2 Walk Through Agent Execution Trace

**Turn 1 - Project Detail Retrieval:**
```
Tool call: get_project_detail({"project_id":"DSPJ-0003"})
```
Agent retrieves full project proposal including claims, milestones, and raw text.

**Turn 2 - Search & Academic Context:**
```
Tool call: search_projects({"query":"LLM evaluation funding proposals public goods","top":5})
Tool call: search_projects({"query":"AI automated evaluation decentralized science","top":5})
Tool call: search_academic_context({"query":"LLM-based evaluation system for funding proposals..."})
```
Agent autonomously identifies related projects and queries academic context.

**Turn 3 - Cross-Project Comparison:**
```
Tool call: compare_projects({"project_ids":["DSPJ-0003", "DSPJ-0002", "DSPJ-0049", "DSPJ-0027"]})
Tool call: search_academic_context({"query":"large language models automated grant review..."})
```
Agent compares target with related projects and deepens academic context search.

**Turn 4 - Final Review:**
```
Agent produced final output.
```
Agent synthesizes all gathered evidence into structured review JSON.

### 2.3 Output Files

```powershell
# View agent trace
cat .\outputs\DSPJ-0003-agent-trace.json

# View structured review
cat .\outputs\DSPJ-0003-agent-review.json
```

**Key demonstration**: GLM-5.1 made 7 tool calls across 4 turns, autonomously deciding when to gather more information before producing the final review.

---

## 3. Reviewer Brief Generation (20 seconds)

```powershell
.\scripts\generate-reviewer-brief.ps1 -ProjectId DSPJ-0003
```

**Output**: `docs/reviewer-briefs/DSPJ-0003-reviewer-brief.md`

The brief includes:
- Executive summary
- Extracted claims (verifiable vs aspirational)
- Milestone assessment
- Evidence found / missing evidence
- Cross-project comparison
- Risk flags with severity
- Suggested reviewer questions

---

## 4. Batch Review (Optional, 10 seconds)

```powershell
.\scripts\run-batch-review.ps1 -SampleSize 5
```

Processes 5 randomly selected projects with agent review workflow.

**Output**: `outputs/batch-summary.json` with aggregated results.

---

## 5. Key Takeaways (20 seconds)

1. **Long-Horizon Task Execution**: GLM-5.1 uses planning and tool calling, not one-shot summarization
2. **Autonomous Tool Selection**: Agent decides which tools to call and in what order
3. **Cross-Project Comparison**: Leverages 49-project Spark dataset for relative assessment
4. **Structured Output**: Review JSON enables downstream brief generation
5. **Human Reviewer Support**: Reduces reviewer workload by surfacing evidence gaps and risks

---

## Demo Caveats

1. **Academic context is real but limited**: The `search_academic_context` tool now uses Semantic Scholar API metadata. It is not exhaustive scientific validation.
2. **No funding decisions**: The agent assists reviewers but does not make funding decisions.
3. **Evidence verification**: Reviewers should verify claims independently; agent flags evidence gaps.
4. **AMiner status**: AMiner integration is planned when API access is available.

---

## Repository Links

- GitHub: https://github.com/Swiftevo/spark-desci-funding-intelligence-agent
- Sample Reviewer Briefs: `docs/reviewer-briefs/`
- Agent Traces: `outputs/`
