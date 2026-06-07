# Demo Remarks

## Academic Context Limitation

The current `search_academic_context` tool is a placeholder adapter.

For the demo, state this clearly:

```text
1. The academic context returned by the tool is placeholder data.
2. GLM-5.1 analysis based on that placeholder is not equivalent to real literature support.
3. The next implementation step is replacing the placeholder with Semantic Scholar or AMiner retrieval.
```

## How To Present This Honestly

Recommended wording:

```text
In this prototype, Spark DeSci project retrieval and GLM-5.1 tool-calling are live.
The academic context layer is currently mocked to demonstrate where AMiner or Semantic Scholar will plug into the workflow.
Therefore, academic_context_results should be interpreted as workflow scaffolding, not verified literature evidence.
```

## Why It Still Matters For The Hackathon

Even with placeholder academic context, the current demo still proves the long-horizon agent structure:

```text
get_project_detail
|
search_projects
|
compare_projects
|
search_academic_context placeholder
|
structured reviewer report
```

The core Z.AI signal is the GLM-5.1 agent loop, tool calling, cross-project retrieval, and human-review support workflow.

## Do Not Claim

```text
Do not claim that AMiner has already verified the project.
Do not claim that academic_context_results are citations.
Do not claim that GLM-5.1 has produced peer-reviewed scientific validation.
```

## Next Integration Step

Replace:

```text
scripts/search-aminer-context.ps1
```

with:

```text
Semantic Scholar retrieval
or
AMiner retrieval when API access is available
```
