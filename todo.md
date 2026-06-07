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

**Status**: In progress
**Priority**: High
**Target**: 2026-06-12

- [x] Clean execution trace output for demo readability
- [x] Convert `outputs/DSPJ-0003-agent-review.json` into a polished reviewer brief for the demo baseline
- [ ] One-click demo script (single project + batch)
- [x] Update README for submission requirements
- [x] Project proposal / documentation
- [ ] Create `DEMO_SCRIPT.md` using the DSPJ-0003 agent trace as the 3-minute demo storyline
- [x] Document safety, cost, and permission boundaries
- [x] Clearly label academic context limitations in demo:
  - [x] Tool-returned academic context is placeholder data.
  - [x] GLM-5.1 analysis based on placeholder context is not real literature support.
  - [x] Next step is replacing the placeholder with Semantic Scholar / AMiner retrieval.
- [x] Add six tracked reviewer brief artifacts under `docs/reviewer-briefs/`
- [x] Push M4 proposal and reviewer brief artifacts to GitHub
- [ ] Final testing and polish

## M5: Final Demo Package

**Status**: Next
**Priority**: Critical
**Target**: 2026-06-09 to 2026-06-12

- [ ] Create `DEMO_SCRIPT.md` with a 3-minute narration
- [ ] Create a one-command demo path for judges
- [ ] Re-run primary project demo when GLM quota is available
- [ ] Record demo video
- [ ] Final README pass after video/demo script
- [ ] Final secret scan before submission

## Deferred (Post-Hackathon)

- [ ] Semantic Scholar API integration (replace dummy academic context)
- [ ] AMiner API integration (when access is obtained)
- [ ] Gitcoin grant round data import (on-chain donation records)
- [ ] Cross-round funding memory comparison
- [ ] Web UI for reviewer briefs
