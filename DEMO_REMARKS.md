# Demo Remarks

## Academic Context Source

The `search_academic_context` tool uses a multi-layer fallback:

```text
1. Semantic Scholar API (primary)
2. OpenAlex API (fallback)
3. Local Academic Cache (40 paper metadata records across 20 domains)
```

Live features:
- Paper search with citation counts and field analysis
- Field maturity assessment (emerging/active/established)
- Credibility questions based on retrieved literature
- Claim-to-literature comparison based on retrieved abstracts when available, or metadata-only signals when abstracts are unavailable
- Open access PDF links when available
- Local metadata cache fallback when both APIs are unavailable

## API Limitations

Semantic Scholar API rate limits may apply. If available, set `SEMANTIC_SCHOLAR_API_KEY` for more stable access.

OpenAlex fallback is available. If available, set `OPENALEX_API_KEY` for higher free daily usage.

For the demo, be aware:

```text
1. Not all project topics will have extensive literature coverage.
2. Some niche DeSci topics may return limited results.
3. Local cache contains 40 paper metadata records across 20 domains - not exhaustive.
4. AMiner API integration is planned for extended coverage.
```

## Local Academic Cache

When both Semantic Scholar and OpenAlex APIs fail, the agent falls back to a local metadata cache:

```text
data/academic-cache/
|-- ai-llm-bias/         (LLM bias and fairness)
|-- biotech-health-ai/   (AI in healthcare)
|-- governance-dao/      (DAO governance)
|-- ocean-coral/         (Coral restoration)
|-- desci-general/       (DeSci overview)
|-- ...                  (20 domains total, 40 paper metadata records)
```

**Cache caveats**:
- Contains metadata only (title, year, citations, DOI, OA link)
- Does not contain full abstracts or paper content
- Pre-cached on 2026-06-10, may not include latest papers
- Intended as fallback, not primary literature source

## How To Present This

Recommended wording:

```text
Spark DeSci project retrieval, GLM-5.1 tool-calling, web evidence checks, and cross-project comparison are live.
Academic context is powered by Semantic Scholar first, then OpenAlex fallback, then local metadata cache for resilience.
Agent analysis is based on retrieved project data, public web metadata, paper metadata, citations, and field maturity signals.
Academic claim comparison is based on retrieved abstracts when available, otherwise metadata-only signals.
```

## Why It Matters For The Hackathon

The current demo proves the long-horizon agent structure with real academic context:

```text
get_project_detail
|
fetch_web_resource (GitHub / website evidence check)
|
search_projects
|
compare_projects
|
search_academic_context (Semantic Scholar -> OpenAlex -> Local Cache)
|
structured reviewer report
```

The core Z.AI signal is the GLM-5.1 agent loop, tool calling, external evidence checks, cross-project retrieval, and multi-layer academic literature support.

## Do Not Claim

```text
Do not claim that Semantic Scholar or OpenAlex results are exhaustive.
Do not claim that academic_context_results are peer-reviewed validation.
Do not claim that GLM-5.1 has produced definitive scientific conclusions.
Do not claim that website or GitHub metadata proves team identity, code quality, or production readiness.
Do not claim that local cache papers are exhaustive, current, or full-text validated.
Do not claim that academic claim comparison is equivalent to full literature review.
```

Human reviewers remain the final decision-makers.

## Next Integration Step

Add AMiner API when access is obtained:

```text
AMiner retrieval for extended Chinese-language literature coverage
```
