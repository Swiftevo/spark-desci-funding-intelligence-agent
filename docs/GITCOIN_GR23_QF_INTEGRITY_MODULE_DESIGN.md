# Gitcoin GR23 DeSci QF Integrity Module Design

## Purpose

This module extends the Spark DeSci Funding Intelligence Agent from proposal review into quadratic funding integrity review.

The goal is not to accuse projects or donors. The goal is to help human operators identify review-worthy funding behavior signals in Gitcoin GR23 DeSci Community Round data.

## Why This Matters

Quadratic funding rewards broad community participation. Small donations can unlock matching pool funds, so round operators need to review whether funding activity reflects genuine community support or suspicious coordination.

Human review is difficult because operators must inspect project applications, payout wallets, donor wallets, transaction hashes, passport scores, repeated donor behavior, and cross-project patterns. This module turns that manual inspection into a structured risk review workflow.

## Input Data

### Project Application Data

Source file:

```text
gitcoin grant 23 desci community round project information.txt
```

Observed fields:

```text
id
projectId
status
title
payoutAddress
signature
website
projectTwitter
projectGithub
userGithub
prior funding
team size
team profiles/socials
project age
project description
DeSci mission alignment
fund use plan
past grant payout wallet addresses
milestones / updates
conflict-of-interest disclosure
```

### Small Donation Data

Source file:

```text
gitcoin grant 23 desci community round small donation.txt
```

Observed fields:

```text
transaction hash / id
projectId
applicationId
roundId
token
voter
grantAddress
amount
amountUSD
coefficient
status
last_score_timestamp
type
success
rawScore
threshold
```

## Privacy Boundary

Raw GR23 data should remain local unless explicitly redacted.

Do not commit raw project applications or donation history to the public repository before review because the files may include:

- wallet addresses
- transaction hashes
- payout addresses
- social profiles
- team information
- conflict-of-interest disclosures
- passport / sybil score fields
- private operator notes if added later

Recommended public demo mode:

```text
Use redacted wallet identifiers:
0xabc...123

Use aggregated risk summaries:
project A has 12 repeated donors, not full donor table

Use graph statistics:
shared donor cluster size, repeated donation count, self-donation flag

Avoid naming donors unless the data is already public and intended for audit publication
```

## Core Review Questions

The module should help human reviewers answer:

1. Did any project receive donations from its own payout wallet?
2. Did any project wallet donate to other projects in the same round?
3. Are there repeated donor clusters across many projects?
4. Are there small-donation patterns that look coordinated?
5. Are low passport / threshold-failed donations concentrated around specific projects?
6. Do donation patterns align with the project’s stated community reach?
7. Are there prior-round wallet disclosures that should be linked to current payout wallets?

## Risk Signals

### 1. Direct Self-Donation

Flag when:

```text
voter == grantAddress
voter == payoutAddress
```

Severity:

```text
high
```

Reason:

```text
Direct self-donation can create matching pool distortion in a quadratic funding round.
```

### 2. Project Wallet Donating To Other Projects

Flag when:

```text
voter is a known payoutAddress from another approved project
```

Severity:

```text
medium to high
```

Reason:

```text
This may indicate legitimate ecosystem support, reciprocal support, or coordinated donation behavior. Human review is required.
```

### 3. Shared Donor Cluster

Flag when one donor wallet donates to many projects.

Example features:

```text
donor_project_count
total_amount_usd
average_amount_usd
threshold_success_rate
raw_score_average
```

Severity depends on:

```text
number of projects touched
amount pattern similarity
passport score quality
timing concentration
```

### 4. Repeated Amount Pattern

Flag when the same donor or donor group uses highly similar amounts across many projects.

Examples:

```text
$1.99 to 10 projects
$2.00 to 12 projects
same token + same amount + similar timestamp
```

Severity:

```text
medium
```

### 5. Low Passport / Failed Threshold Concentration

Flag when a project receives many donations where:

```text
success == FALSE
rawScore < threshold
```

Severity:

```text
medium
```

Reason:

```text
Failed or low-quality identity signals may indicate sybil risk, but they are not proof of misconduct.
```

### 6. Payout Wallet History Link

Flag when an application discloses past payout wallets and those wallets appear in current donor activity.

Severity:

```text
medium
```

Reason:

```text
Past wallet continuity can help explain legitimate reuse, but undisclosed wallet overlap can require review.
```

## Graph Model

Represent the round as a bipartite graph:

```text
Donor Wallet -> Project / Grant Address
```

Node types:

```text
donor_wallet
project
grant_address
payout_address
past_payout_address
```

Edge attributes:

```text
tx_hash
token
amount
amountUSD
status
success
rawScore
threshold
timestamp
```

Useful graph outputs:

```text
top shared donors
projects with high shared donor overlap
donor clusters
project-to-project wallet interactions
self-donation flags
failed-threshold donation concentration
```

## Proposed Tool Layer

### import_gr23_projects

Input:

```text
project information TXT / TSV
```

Output:

```json
{
  "projects": [],
  "wallet_index": {},
  "redaction_map": {}
}
```

### import_gr23_donations

Input:

```text
small donation TXT / TSV
```

Output:

```json
{
  "donations": [],
  "donor_index": {},
  "grant_index": {}
}
```

### analyze_self_donation

Checks:

```text
voter == grantAddress
voter == project payoutAddress
voter in past payout wallet list
```

### analyze_shared_donors

Checks:

```text
donors supporting multiple projects
common donor clusters
overlap ratio between projects
```

### analyze_passport_risk

Checks:

```text
success false rate
rawScore distribution
threshold failure concentration
```

### generate_qf_integrity_report

Output:

```json
{
  "round": "Gitcoin GR23 DeSci Community Round",
  "project_count": 0,
  "donation_count": 0,
  "risk_summary": [],
  "project_reports": [],
  "graph_summary": {},
  "human_review_questions": []
}
```

## Agent Workflow

```text
1. Load project applications
2. Load donation history
3. Build wallet index
4. Link projectId / applicationId / grantAddress / payoutAddress
5. Check direct self-donation
6. Check project wallet cross-donations
7. Detect repeated donor clusters
8. Analyze passport / threshold score concentration
9. Generate project-level risk summaries
10. Generate round-level integrity report
11. Ask GLM-5.1 to synthesize human reviewer questions
```

## GLM-5.1 Role

GLM-5.1 should not be the primary calculator for wallet matching. Deterministic scripts should compute the graph and risk signals.

GLM-5.1 should be used for:

- explaining risk patterns in human language
- grouping signals into reviewer-friendly summaries
- generating follow-up questions
- comparing application claims with donation behavior
- distinguishing possible benign explanations from review-worthy risks

## Output Types

### Project Integrity Brief

Per project:

```text
Project name
Payout wallet
Donation count
Unique donor count
Total small donation USD
Self-donation flags
Shared donor cluster flags
Passport / threshold risk
Reviewer questions
```

### Round Integrity Summary

For the whole round:

```text
number of approved projects
number of donation transactions
unique donor wallets
top shared donor clusters
projects requiring manual review
high-level graph observations
```

### Graph Export

Recommended formats:

```text
CSV edge list
JSON graph
GraphML
```

Possible visualization tools:

```text
Gephi
Observable
D3.js
Python networkx
```

## Human Review Boundary

The report must avoid direct accusations.

Preferred language:

```text
review-worthy signal
requires manual verification
possible coordination pattern
possible benign explanation
not proof of misconduct
```

Avoid language:

```text
fraud
attack
scam
confirmed sybil
guilty
```

## Demo Scope

Recommended demo:

```text
Use a redacted sample of 3 to 5 projects.
Show direct wallet matching and donor cluster summary.
Show one project-level integrity brief.
Show one round-level graph summary.
Do not publish raw donor wallet table in demo slides.
```

## Roadmap

### M1: Local Import And Redaction

- [x] Parse project application TXT / TSV
- [x] Parse small donation TXT / TSV
- [x] Generate redacted local JSON
- [x] Create wallet redaction map
- [x] Keep generated outputs under ignored `outputs/gr23-integrity/`
- [x] Verify public redacted outputs contain no raw wallet addresses or transaction hashes

Current local import result:

```text
Projects: 21
Donations: 274
Unique donors: 80
Failed threshold donations: 91
```

Command:

```powershell
.\scripts\import-gr23-data.ps1
```

### M2: Deterministic Risk Analysis

- [x] Direct self-donation checks
- [x] Project wallet cross-donation checks
- [x] Shared donor cluster analysis
- [x] Repeated amount pattern analysis
- [x] Passport / threshold concentration analysis
- [x] Redacted donor-project graph export

Current local analysis result:

```text
Direct self-donation signals: 0
Project wallet cross-donation signals: 19
Shared donor clusters: 16
Repeated amount patterns: 25
Failed threshold rate: 0.3321
```

Command:

```powershell
.\scripts\analyze-gr23-integrity.ps1
```

Generated local outputs:

```text
outputs/gr23-integrity/gr23-integrity-report.json
outputs/gr23-integrity/gr23-project-risk-summary.json
outputs/gr23-integrity/gr23-donor-project-graph.json
outputs/gr23-integrity/gr23-donor-project-edges.csv
```

All outputs are redacted review signals. They should not be treated as proof of misconduct.

### M3: GLM Reviewer Brief

- Feed deterministic findings to GLM-5.1
- Generate reviewer-friendly explanations
- Generate human follow-up questions

### M4: Graph Export

- Export donor-project edge list
- Export project overlap matrix
- Export redacted graph JSON

### M5: Demo And Governance Boundary

- Add public demo with redacted data
- Document that outputs are risk signals only
- Keep raw data local unless explicit permission is granted
