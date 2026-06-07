# Hackathon Alignment

## Target Track

Z.AI Web3 + Long-Horizon Task

## Project Thesis

Most AI reviewer demos stop at:

```text
Proposal -> Summary
```

This project should demonstrate:

```text
Funding round -> Proposal intake -> Evidence checking -> Academic context -> Cross-project comparison -> Risk detection -> Reviewer brief
```

That makes it a long-horizon workflow rather than a simple summarization task.

## Required Signals For Judges

The demo and README should make these signals obvious:

```text
GLM-5.1 is used as the reasoning/review engine
Spark DeSci 49-project dataset is used as real domain data
AMiner is represented as the academic context layer
The agent performs multiple review steps
Human reviewers remain final decision-makers
The output reduces reviewer workload
```

## Submission Artifacts

Expected artifacts:

```text
GitHub repo
README with setup and demo instructions
3-minute demo video
Project proposal / pitch
Evidence of GLM-5.1 usage
Evidence of Spark dataset usage
AMiner integration or adapter explanation
Generated reviewer report example
```

## Demo Narrative

Recommended 3-minute flow:

```text
1. Show the pain: DeSci funding reviewers must inspect many proposals and scientific claims.
2. Show Spark dataset: 49 real DeSci projects are imported.
3. Search a project: retrieve a relevant project from Spark DB.
4. Run GLM-5.1 review: extract claims, risks, missing evidence, AMiner queries.
5. Show reviewer brief: human-readable output for reviewers.
6. Explain next step: real AMiner context and cross-round memory.
```

## Minimum Bar Before Submission

```text
README is clear enough for judges to run
No API keys or secrets are committed
At least one GLM-5.1 output artifact is included or reproducible
At least one reviewer brief is generated from a real Spark project
The repo explains dummy vs real components honestly
The demo shows long-horizon workflow steps
```

## Red Flags To Avoid

```text
Do not claim the system makes final funding decisions.
Do not present dummy AMiner output as real AMiner results.
Do not hide missing evidence or limitations.
Do not make the project look like a generic AI summarizer.
Do not commit API keys, local environment files, or private credentials.
```
