# Milestones & TODO

## M1: Agent Core with GLM Function Calling

**Status**: Done
**Priority**: Critical
**Completed**: 2026-06-07

- [x] Create `run-agent-review.ps1` - main agent loop script
- [x] Define GLM function calling tool schemas (search_projects, get_project_detail, compare_projects, search_academic_context)
- [x] Implement tool execution functions in PowerShell
- [x] Implement multi-turn conversation loop (send messages -> receive tool_calls -> execute tools -> feed results back -> repeat)
- [x] Output execution trace showing GLM's autonomous decisions
- [x] Output structured review JSON
- [x] Test with DSPJ-0003 - 4 turns, 7 tool calls, successful
- [x] Token optimization: compress tool results, MaxTurns 6, compact system prompt

## M2: Batch Review (5 Random Projects)

**Status**: Done for prototype demo
**Priority**: High
**Completed**: 2026-06-07

- [x] Create `run-batch-review.ps1`
- [x] Random selection of 5 projects from projects.json
- [x] Loop through selected projects using agent review
- [x] Aggregate output: `outputs/batch-summary.json`
- [x] Error handling and retry logic
- [x] Progress display
- [x] Execute batch / multiple project reviews with API key
- [x] Generate tracked reviewer brief artifacts for six selected projects

## M3: Prompt Quality & Cross-Project Comparison

**Status**: Done for hackathon prototype
**Priority**: High
**Completed**: 2026-06-07

- [x] Optimize system prompt for agent role
- [x] Add cross-project comparison instructions (same domain, overlapping claims)
- [x] Enhance reviewer brief with comparison section
- [x] Improve risk assessment accuracy
- [x] Distinguish verifiable claims from aspirational claims
- [x] Add academic review prompts for duplication, novelty, and gap identification
- [x] Keep funding memory focused on DeSci alignment and same-round comparison
- [x] Test and iterate on prompt quality

## M4: Demo Preparation & Submission

**Status**: Done
**Priority**: High
**Completed**: 2026-06-10

- [x] Clean execution trace output for demo readability
- [x] Convert `outputs/DSPJ-0003-agent-review.json` into a polished reviewer brief for the demo baseline
- [x] One-click demo script (single project + batch)
- [x] Update README for submission requirements
- [x] Project proposal / documentation
- [x] Create `DEMO_SCRIPT.md` using the DSPJ-0003 agent trace as the 3-minute demo storyline
- [x] Document safety, cost, and permission boundaries
- [x] Clearly label academic context limitations in demo:
  - [x] Semantic Scholar and OpenAlex metadata are real retrieved literature metadata, but not exhaustive validation.
  - [x] GLM-5.1 analysis based on retrieved literature still needs human review.
  - [x] Next step is adding AMiner retrieval when access is available.
- [x] Add six tracked reviewer brief artifacts under `docs/reviewer-briefs/`
- [x] Push M4 proposal and reviewer brief artifacts to GitHub

## M5: Final Demo Package

**Status**: In progress
**Priority**: Critical
**Target**: 2026-06-10 to 2026-06-13

- [x] Create `DEMO_SCRIPT.md` with a 3-minute narration
- [x] Create a one-command demo path for judges
- [x] Add public web evidence checks for GitHub repositories and project websites
- [x] Add local academic metadata cache fallback for API outage / rate-limit resilience
- [x] Add academic claim comparison field for abstract/metadata-based literature comparison
- [x] Document multi-layer academic fallback in README and demo remarks
- [ ] Complete dry run using Spark retrieval, web evidence check, academic cache check, and reviewer brief walkthrough
- [ ] Add timestamped run archive under `outputs/runs/YYYY-MM-DD-HHMM-ProjectId/`
- [ ] Preserve agent review JSON, trace JSON, and reviewer brief per archived run
- [ ] Document archived runs as an audit trail for prompt/model/tool improvement
- [ ] Re-run primary project demo when GLM quota is available
- [ ] Add lightweight local demo dashboard frontend for reviewer briefs, agent traces, academic context, risks, and missing evidence
- [ ] Record demo video
- [ ] Final README pass after video/demo script
- [ ] Final secret scan before submission

## Deferred (Post-Hackathon)

- [ ] M6: Gitcoin DeSci QF Integrity Agent
  - [x] Draft `docs/GITCOIN_GR23_QF_INTEGRITY_MODULE_DESIGN.md`
  - [x] Create `scripts/import-gr23-data.ps1` for local-only import and redaction
  - [x] Import Gitcoin DeSci Round 23 project applications locally
  - [x] Import small donation history locally
  - [x] Generate redacted local JSON and private redaction map under ignored `outputs/gr23-integrity/`
  - [x] Verify redacted outputs do not contain raw wallet addresses or transaction hashes
  - [ ] Redact personal fields before any future public data commit (email, Telegram, private reviewer comments)
  - [ ] Detect direct self-donation (`voter == grantAddress` / `voter == payoutAddress`)
  - [ ] Detect project payout wallets acting as donors to other projects
  - [ ] Detect repeated amount and broad donor patterns
  - [ ] Detect shared donor clusters between projects
  - [ ] Summarize passport / sybil score failure concentration by project
  - [ ] Build donor-project graph JSON
  - [ ] Generate funding integrity brief with human-review-safe language
- [ ] AMiner API integration (when access is obtained)
- [ ] Gitcoin grant round data import (on-chain donation records)
- [ ] Cross-round funding memory comparison
- [ ] Web UI for reviewer briefs beyond the local hackathon demo dashboard
