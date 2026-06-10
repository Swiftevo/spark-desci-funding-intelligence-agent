# Delivery Checklist

## Status Legend

```text
[x] Done
[ ] Not done
[~] In progress / needs review
```

## Core Build

```text
[x] Import 49 Spark DeSci projects
[x] Search Spark projects with weighted relevance
[x] Fetch project detail by ID
[x] Run dummy end-to-end review workflow
[x] Run real GLM-5.1 single-project review
[x] Generate polished reviewer brief from GLM-5.1 output
[x] Replace or clearly label dummy AMiner adapter
[x] Add batch or comparison workflow for multiple projects
```

## GitHub / Repo

```text
[x] Initialize git repo
[x] Add .gitignore
[x] Create GitHub repository
[x] Commit current prototype
[x] Push main branch
[x] Add project context and hackathon alignment docs
[x] Ensure no secrets are committed
```

## Demo / Submission

```text
[x] Choose primary demo project ID
[x] Generate final GLM-5.1 reviewer output
[x] Generate final reviewer brief
[x] Write 3-minute demo script
[x] Add public web evidence check demo step
[x] Add local academic cache fallback demo step
[ ] Complete dry run checklist
[ ] Record demo video
[x] Prepare submission proposal text
[x] Confirm GitHub README has setup, usage, and architecture
```

## Review Criteria For Codex

Before any major GLM/OpenCode-generated change is accepted:

```text
[ ] Does it support the long-horizon review workflow?
[ ] Does it keep human review oversight?
[ ] Does it use Spark data meaningfully?
[ ] Does it keep AMiner claims honest?
[ ] Does it keep Semantic Scholar, OpenAlex, and local cache claims honest?
[ ] Does it avoid overstating GitHub / website metadata checks?
[ ] Does it avoid committing secrets?
[ ] Does it keep commands runnable on Windows PowerShell?
```
