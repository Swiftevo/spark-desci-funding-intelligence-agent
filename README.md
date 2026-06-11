# Spark DeSci Funding Intelligence Agent（繁體中文）

本專案使用 GLM-5.1 協助 DeSci funding round 的人類評審，從 Spark DeSci 49 個真實項目資料中產生結構化的評審支援。

GitHub repo:

```text
https://github.com/Swiftevo/spark-desci-funding-intelligence-agent
```

本專案參與 AI x Web3 Agentic Builders Hackathon 的 **Z.AI Track - Web3 x Long-Horizon Task**。

## 黑客松賽道定位

核心評審訊號：

- 以 GLM-5.1 作為長流程推理與評審支援核心
- Agent 使用 planning 與 tool calling，而不是一次性 proposal summary
- 工作流程對應真實 DeSci funding review 痛點
- Demo 可在 Windows PowerShell 中執行

## 架構

### 目前的 Scripted Pipeline

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

### 目前的 GLM-5.1 Agent Loop

```text
User: Review project DSPJ-0003
|
GLM-5.1 agent loop
|-- get_project_detail
|-- fetch_web_resource (GitHub / website evidence check)
|-- search_projects
|-- compare_projects
|-- search_academic_context (Semantic Scholar, OpenAlex fallback, local cache fallback)
|
Structured review JSON
|
generate-reviewer-brief.ps1
|
Reviewer brief Markdown
```

Agent 可使用的工具：

| Tool | 用途 |
|------|------|
| `search_projects` | 搜尋 Spark 49 個項目資料集 |
| `get_project_detail` | 透過 Project ID 取得完整項目資料 |
| `fetch_web_resource` | 檢查 GitHub repo、Artizen page、項目網站等公開 evidence signal |
| `compare_projects` | 將目標項目與相關項目作同輪比較 |
| `search_academic_context` | 先查 Semantic Scholar，再 fallback 到 OpenAlex，最後使用本地學術 metadata cache |

## 學術背景來源

`search_academic_context` 目前使用三層學術檢索：

```text
1. Semantic Scholar API（主要即時來源）
2. OpenAlex API（Semantic Scholar rate limit 或不可用時 fallback）
3. Local academic metadata cache（兩個即時 API 都不可用時的最後 fallback）
```

功能包括：

- 搜尋論文 metadata、引用數與研究領域
- 判斷 field maturity（emerging / active / established）
- 產生 credibility questions，協助評審追問文獻支持
- 在有 abstract 時進行 claim-to-literature comparison
- 若只有 metadata，則標示為 metadata-only signal
- 在可用時提供 open access PDF link

Demo 限制：

```text
1. Semantic Scholar API 可能遇到 rate limit；如有 API key 可設定 SEMANTIC_SCHOLAR_API_KEY。
2. OpenAlex fallback 可用；如有 API key 可設定 OPENALEX_API_KEY。
3. 本地 academic cache 只包含 metadata，不包含 PDF、全文、abstract 或完整文獻覆蓋。
4. 並非所有 DeSci 題目都有充分文獻。
5. AMiner API 是下一步，尚未接入。
6. Agent 的 claim comparison 受限於 retrieved abstracts / metadata，仍需人類文獻審查。
```

目前已完成：Spark project retrieval、GLM-5.1 tool calling、跨項目比較、Semantic Scholar 學術背景、OpenAlex fallback、本地 academic metadata cache fallback、web evidence check。

## 快速開始

設定 Z.AI API key：

```powershell
$env:ZAI_API_KEY="your_api_key"
# Optional:
$env:SEMANTIC_SCHOLAR_API_KEY="your_semantic_scholar_key"
$env:OPENALEX_API_KEY="your_openalex_key"
```

### 一鍵 Demo

錄影版 demo 使用 OpenCode + GLM-5.1 via `xixixixi/glm-5.1`；詳見 [DEMO_SCRIPT.md](./DEMO_SCRIPT.md)。以下 PowerShell 直接 Z.AI API 路徑是可重現版本，需要 `ZAI_API_KEY`。

錄影或提交前，請使用 [DRY_RUN_CHECKLIST.md](./DRY_RUN_CHECKLIST.md) 檢查 Spark retrieval、web evidence check、Semantic Scholar / OpenAlex / local cache academic context、reviewer brief walkthrough，以及 final secret scan。

執行完整 demo：

```powershell
.\scripts\demo.ps1 -ProjectId DSPJ-0003
```

加上 batch review：

```powershell
.\scripts\demo.ps1 -ProjectId DSPJ-0003 -BatchSize 5
```

### 分步執行

匯入 Spark DeSci 項目：

```powershell
.\scripts\import-spark-data.ps1
```

搜尋與查看項目：

```powershell
.\scripts\search-projects.ps1 -Query "AI funding evaluator" -Top 5
.\scripts\get-project-detail.ps1 -ProjectId DSPJ-0030
```

執行 GLM-5.1 agent loop：

```powershell
.\scripts\run-agent-review.ps1 -ProjectId DSPJ-0003 -MaxRetries 2
```

產生 reviewer brief：

```powershell
.\scripts\generate-reviewer-brief.ps1 -ProjectId DSPJ-0003
```

執行 batch agent reviews：

```powershell
.\scripts\run-batch-review.ps1 -SampleSize 5
```

測試 GLM-5.1 連線：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-glm.ps1
```

## 輸出結構

本地生成結果會寫入：

```text
outputs/
```

已追蹤的 demo reviewer brief artifacts：

```text
docs/reviewer-briefs/
```

目前已包含：

```text
DSPJ-0003-reviewer-brief.md
DSPJ-0003-reviewer-brief.zh.md
DSPJ-0006-reviewer-brief.md
DSPJ-0007-reviewer-brief.md
DSPJ-0018-reviewer-brief.md
DSPJ-0020-reviewer-brief.md
DSPJ-0038-reviewer-brief.md
```

## API 額度提示

如果 Z.AI 回傳：

```json
{"error":{"code":"1113","message":"Insufficient balance or no resource package. Please recharge."}}
```

請在 Z.AI dashboard 充值或啟用 API resource package 後再重試。

## 主要 Script 對照

| Current | Target |
|---------|--------|
| `run-dummy-review.ps1` | 無 API fallback |
| `run-glm-project-review.ps1` | Single-call GLM baseline |
| `run-agent-review.ps1` | 主要 GLM-5.1 function-calling agent loop |
| `generate-reviewer-brief.ps1` | 將 agent review JSON 轉成 Markdown reviewer brief |
| `fetch-web-resource.ps1` | 檢查 GitHub / website metadata-level evidence |
| `search-semantic-scholar.ps1` | Semantic Scholar academic context search |
| `search-openalex.ps1` | OpenAlex academic fallback |
| `search-academic-cache.ps1` | 即時 API 不可用時搜尋本地 academic metadata cache |
| `build-academic-cache.ps1` | 從 OpenAlex metadata 建立 20-domain local academic cache |

## Roadmap

請見 [todo.md](./todo.md)。

### 下一個模組：Gitcoin DeSci QF Integrity Agent

下一步計劃把 reviewer support 從 proposal / academic analysis 延伸到 Gitcoin DeSci quadratic funding 的 funding integrity review。

預計輸入：

```text
Gitcoin DeSci project applications
Small donation history
Project payout wallets
Donor wallet addresses
Transaction hashes
Passport / sybil score fields
```

預計檢查：

- 直接 self-donation：`voter == grantAddress` 或 `voter == payoutAddress`
- 項目 payout wallet 是否作為 donor 捐給其他項目
- 多項目重複小額捐款模式
- 項目之間 shared donor clusters
- passport / sybil score failure 在項目層面的集中情況
- donor-project graph export 供人類審查

邊界：

```text
Integrity module 只標記 risk signals 供人類審查。
未經 operator verification，不應指控任何項目不當行為。
公開 commit 前必須 redacted email、Telegram、private reviewer comments 等個人欄位。
```

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
- [Semantic Scholar API](https://api.semanticscholar.org/) - live academic context
- [OpenAlex API](https://developers.openalex.org/) - live academic fallback
- Local academic metadata cache - final fallback when live academic APIs are unavailable
- [AMiner API](https://www.aminer.cn/) - planned academic context, pending API access

---

## English Version

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
|-- fetch_web_resource (GitHub / website evidence check)
|-- search_projects
|-- compare_projects
|-- search_academic_context (Semantic Scholar, OpenAlex fallback, local cache fallback)
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
| `fetch_web_resource` | Check GitHub repositories, Artizen pages, and project websites for public evidence signals |
| `compare_projects` | Compare the target with related projects |
| `search_academic_context` | Search Semantic Scholar first, then fallback to OpenAlex and finally local academic metadata cache if APIs are unavailable |

## Academic Context Source

The `search_academic_context` tool now uses **Semantic Scholar API** for primary academic literature retrieval, **OpenAlex API** as a fallback when Semantic Scholar is rate limited or unavailable, and a small **local academic metadata cache** as the final fallback when both APIs fail.

Key features:
- Paper search with citation counts and field analysis
- Field maturity assessment (emerging/active/established)
- Credibility questions based on retrieved literature
- Claim-to-literature comparison based on retrieved abstracts when available, or metadata-only signals when abstracts are unavailable
- Open access PDF links when available

Demo caveats:

```text
1. Semantic Scholar API rate limits may apply. If available, set `SEMANTIC_SCHOLAR_API_KEY` for more stable access.
2. OpenAlex fallback is available. If available, set `OPENALEX_API_KEY` for higher free daily usage.
3. Local academic cache is metadata-only; it does not contain PDFs, full text, abstracts, or exhaustive coverage.
4. Not all projects will have extensive literature; some topics may have limited results.
5. The next step is adding AMiner API when access is obtained.
6. Agent claim comparison is limited by the retrieved abstracts/metadata and still requires human literature review.
```

Spark project retrieval, GLM-5.1 tool calling, Spark cross-project comparison, Semantic Scholar academic context, OpenAlex fallback, and local academic metadata cache fallback are all live.

## Quick Start

Set your Z.AI API key:

```powershell
$env:ZAI_API_KEY="your_api_key"
# Optional, if you have one:
$env:SEMANTIC_SCHOLAR_API_KEY="your_semantic_scholar_key"
$env:OPENALEX_API_KEY="your_openalex_key"
```

### One-Click Demo

The recorded hackathon demo uses OpenCode with GLM-5.1 via `xixixixi/glm-5.1`; see [DEMO_SCRIPT.md](./DEMO_SCRIPT.md). The PowerShell command below is the optional direct Z.AI API path and requires `ZAI_API_KEY`.

Before recording, use [DRY_RUN_CHECKLIST.md](./DRY_RUN_CHECKLIST.md) to verify Spark retrieval, web evidence checks, Semantic Scholar/OpenAlex/local cache academic context, reviewer brief walkthrough, and final secret scan.

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
DSPJ-0003-reviewer-brief.zh.md
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
| `fetch-web-resource.ps1` | Check public GitHub repositories and project websites for metadata-level evidence |
| `search-semantic-scholar.ps1` | Academic context search via Semantic Scholar API |
| `search-openalex.ps1` | Academic context search via OpenAlex API and fallback support |
| `search-academic-cache.ps1` | Search the local academic metadata cache when live APIs are unavailable |
| `build-academic-cache.ps1` | Build the 20-domain local academic metadata cache from OpenAlex metadata |

## Roadmap

See [todo.md](./todo.md) for milestones and progress.

### Next Module: Gitcoin DeSci QF Integrity Agent

The next planned module extends reviewer support from proposal and academic analysis into funding integrity review for Gitcoin DeSci quadratic funding rounds.

Planned inputs:

```text
Gitcoin DeSci project applications
Small donation history
Project payout wallets
Donor wallet addresses
Transaction hashes
Passport / sybil score fields
```

Planned checks:

- Direct self-donation signal: `voter == grantAddress` or `voter == payoutAddress`
- Project wallet as donor: a known project payout wallet donating to other projects
- Repeated small-amount donation patterns across many projects
- Shared donor clusters between projects
- Passport / sybil score failure concentration by project
- Donor-project graph export for human review

Boundary:

```text
The integrity module should flag risk signals for human review.
It must not accuse a project of misconduct without operator verification.
Personal fields such as email, Telegram, and private reviewer comments should be redacted before public commit.
```

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
- [OpenAlex API](https://developers.openalex.org/) - academic context fallback (live)
- Local academic metadata cache - final fallback when live academic APIs are unavailable
- [AMiner API](https://www.aminer.cn/) - academic context planned, pending API access
