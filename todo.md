# Milestones & TODO

## M1: Agent Core with GLM Function Calling

**Status**: Not started
**Priority**: Critical
**Target**: 2026-06-08

- [ ] Create `run-agent-review.ps1` — main agent loop script
- [ ] Define GLM function calling tool schemas (search_projects, get_project_detail, compare_projects, search_academic_context, generate_reviewer_brief)
- [ ] Implement tool execution functions in PowerShell
- [ ] Implement multi-turn conversation loop (send messages → receive tool_calls → execute tools → feed results back → repeat)
- [ ] Output execution trace showing GLM's autonomous decisions
- [ ] Output structured review JSON
- [ ] Output reviewer brief Markdown
- [ ] Test with 1-2 projects

## M2: Batch Review (5 Random Projects)

**Status**: Not started
**Priority**: High
**Target**: 2026-06-09

- [ ] Create `run-batch-review.ps1`
- [ ] Random selection of 5 projects from projects.json
- [ ] Loop through selected projects using agent review
- [ ] Per-project output: review JSON + reviewer brief + execution trace
- [ ] Aggregate output: `outputs/batch-summary.json`
- [ ] Error handling and retry logic
- [ ] Progress display

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
- [ ] Final testing and polish

## Deferred (Post-Hackathon)

- [ ] Semantic Scholar API integration (replace dummy academic context)
- [ ] AMiner API integration (when access is obtained)
- [ ] Gitcoin grant round data import (on-chain donation records)
- [ ] Cross-round funding memory comparison
- [ ] Web UI for reviewer briefs
