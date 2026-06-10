# Demo Remarks

## Academic Context Source

The `search_academic_context` tool now uses **Semantic Scholar API** for real academic literature retrieval.

Live features:
- Paper search with citation counts and field analysis
- Field maturity assessment (emerging/active/established)
- Credibility questions based on retrieved literature
- Open access PDF links when available

## API Limitations

Semantic Scholar API rate limits may apply. If available, set `SEMANTIC_SCHOLAR_API_KEY` for more stable access.

For the demo, be aware:

```text
1. Not all project topics will have extensive literature coverage.
2. Some niche DeSci topics may return limited results.
3. AMiner API integration is planned for extended coverage.
```

## How To Present This

Recommended wording:

```text
Spark DeSci project retrieval, GLM-5.1 tool-calling, and cross-project comparison are live.
Academic context is now powered by Semantic Scholar API for real literature retrieval.
Agent analysis is based on retrieved papers, citations, and field maturity signals.
```

## Why It Matters For The Hackathon

The current demo proves the long-horizon agent structure with real academic context:

```text
get_project_detail
|
search_projects
|
compare_projects
|
search_academic_context (Semantic Scholar)
|
structured reviewer report
```

The core Z.AI signal is the GLM-5.1 agent loop, tool calling, cross-project retrieval, and real academic literature support.

## Do Not Claim

```text
Do not claim that Semantic Scholar results are exhaustive.
Do not claim that academic_context_results are peer-reviewed validation.
Do not claim that GLM-5.1 has produced definitive scientific conclusions.
```

Human reviewers remain the final decision-makers.

## Next Integration Step

Add AMiner API when access is obtained:

```text
AMiner retrieval for extended Chinese-language literature coverage
```
