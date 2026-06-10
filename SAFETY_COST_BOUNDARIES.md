# Safety, Cost & Permission Boundaries

## Model Usage

- **Model**: GLM-5.1 via Z.AI API (`https://api.z.ai/api/paas/v4/chat/completions`)
- **Authentication**: Bearer token via `ZAI_API_KEY` environment variable
- **API key handling**: Never committed to git. Set per-session in PowerShell. Not logged in output files.

## Cost Boundaries

| Scenario | Estimated API Calls | Token Estimate |
|----------|-------------------|----------------|
| Single project review | 4 turns, 5-7 tool calls | ~8,000-12,000 tokens |
| Batch 5 projects | 20-35 tool calls | ~40,000-60,000 tokens |
| Batch 49 projects (full) | 200+ tool calls | ~400,000+ tokens |

Mitigations:
- `MaxTurns = 6` prevents runaway loops
- `MaxRetries = 2` with exponential backoff (5s, 10s) for transient failures
- Tool results are compressed (empty fields removed, raw_text truncated to 1200 chars)
- System prompt is compact (no JSON examples)
- Default batch size is 5 projects, not 49

## Permission Boundaries

- **The agent does NOT make funding decisions.** It produces review support for human reviewers.
- **The agent does NOT modify any data.** All tools are read-only (search, get, compare).
- **External access is limited** to the Z.AI API, Semantic Scholar API, and the local projects.json file.
- **No on-chain transactions.** The agent reads Spark DeSci project metadata only.

## Failure Handling

| Failure Mode | Behavior |
|-------------|----------|
| API connection lost | Retry up to MaxRetries with exponential backoff |
| API rate limit (429) | Retry after delay |
| Invalid project ID | Return error JSON, agent continues |
| Model produces malformed JSON | Script exits with error, no partial output written |
| MaxTurns exceeded | Script exits with error message |

## Data Privacy

- Project data is public (Spark DeSci funding round, Artizen platform)
- No personal user data is processed
- No on-chain wallet addresses or private keys are accessed
- Output files contain only structured review analysis of public proposals

## Known Limitations

1. **Academic context is real but limited.** The `search_academic_context` tool uses Semantic Scholar metadata. It is useful for literature orientation, but it is not exhaustive validation and does not replace human review. AMiner integration is still planned. See [DEMO_REMARKS.md](./DEMO_REMARKS.md).
2. **No cross-round funding memory.** Only Spark DeSci Season 6 data is imported.
3. **No real-time data.** Projects.json is a static snapshot from the desci-funding-data-layer export.
4. **Single-language.** All prompts and output are in English. Project proposals may contain other languages.
