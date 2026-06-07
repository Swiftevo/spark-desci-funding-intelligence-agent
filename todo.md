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

**Status**: Script ready, not yet executed
**Priority**: High
**Target**: 2026-06-08

- [x] Create `run-batch-review.ps1`
- [x] Random selection of 5 projects from projects.json
- [x] Loop through selected projects using agent review
- [x] Aggregate output: `outputs/batch-summary.json`
- [x] Error handling and retry logic
- [x] Progress display
- [ ] Execute batch review with API key

## M3: Prompt Quality & Cross-Project Comparison

**Status**: Not started
**Priority**: High
**Target**: 2026-06-10

- [ ] Optimize system prompt for agent role
- [ ] Add cross-project comparison instructions (same domain, overlapping claims)
- [ ] Enhance reviewer brief with comparison section
- [ ] Improve risk assessment accuracy
- [ ] Test and iterate on prompt quality

## M4: Demo Preparation & Submission

**Status**: In progress
**Priority**: High
**Target**: 2026-06-12

- [ ] Clean execution trace output for demo readability
- [ ] Convert `outputs/DSPJ-0003-agent-review.json` into a polished reviewer brief for the demo baseline
- [ ] One-click demo script (single project + batch)
- [ ] Update README for submission requirements
- [ ] Project proposal / documentation
- [ ] Create `DEMO_SCRIPT.md` using the DSPJ-0003 agent trace as the 3-minute demo storyline
- [ ] Document safety, cost, and permission boundaries
- [ ] Clearly label academic context limitations in demo:
  - [ ] Tool-returned academic context is placeholder data.
  - [ ] GLM-5.1 analysis based on placeholder context is not real literature support.
  - [ ] Next step is replacing the placeholder with Semantic Scholar / AMiner retrieval.
- [ ] Final testing and polish

## Deferred (Post-Hackathon)

- [ ] Semantic Scholar API integration (replace dummy academic context)
- [ ] AMiner API integration (when access is obtained)
- [ ] Gitcoin grant round data import (on-chain donation records)
- [ ] Cross-round funding memory comparison
- [ ] Web UI for reviewer briefs
