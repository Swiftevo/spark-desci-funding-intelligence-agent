param(
  [string]$ProjectId = "DSPJ-0003",
  [string]$ReviewPath = "",
  [string]$OutDir = ".\outputs"
)

$ErrorActionPreference = "Stop"

if (-not $ReviewPath) {
  $ReviewPath = Join-Path $OutDir "$ProjectId-agent-review.json"
}

if (-not (Test-Path -LiteralPath $ReviewPath)) {
  Write-Error "Review file not found: $ReviewPath. Run run-agent-review.ps1 first."
}

$review = Get-Content -LiteralPath $ReviewPath -Raw | ConvertFrom-Json

$projectIdOut = if ($review.project_entity_id) { $review.project_entity_id } else { $ProjectId }
$name = $review.project_name
$partId = $review.participation_id
$mode = $review.mode
$status = $review.human_review_support_status
$summary = $review.executive_summary

$claimLines = foreach ($c in $review.extracted_claims) {
  "- $c"
}

$milestoneLines = foreach ($m in $review.milestone_assessment) {
  "- $m"
}

$evidenceLines = foreach ($e in $review.evidence_found) {
  "- $e"
}

$missingLines = foreach ($m in $review.missing_evidence) {
  "- $m"
}

$academicLines = foreach ($a in $review.academic_context_results) {
  "- $a"
}

$academicComparisonLines = @()
if ($review.academic_claim_comparison) {
  $academicComparisonLines = foreach ($item in $review.academic_claim_comparison) {
    $papers = @($item.related_papers) -join "; "
    "- Claim: $($item.project_claim)`n  - Related papers: $papers`n  - Signal: $($item.paper_signal)`n  - Evidence basis: $($item.evidence_basis)`n  - Reasoning: $($item.reasoning)`n  - Limitation: $($item.limitation)"
  }
} else {
  $academicComparisonLines = @("- Not available in this review output.")
}

$fundingLines = foreach ($f in $review.funding_memory_observations) {
  "- $f"
}

$riskLines = foreach ($r in $review.risk_flags) {
  "- [$($r.severity)] $($r.risk): $($r.reason)"
}

$questionLines = foreach ($q in $review.suggested_reviewer_questions) {
  "- $q"
}

$comparison = $review.cross_project_comparison

$brief = @"
# Spark DeSci Reviewer Brief

**Project**: $name
**Project ID**: $projectIdOut
**Participation ID**: $partId
**Mode**: $mode
**Review Status**: $status

## Executive Summary

$summary

## Extracted Claims

$($claimLines -join "`n")

## Milestone Assessment

$($milestoneLines -join "`n")

## Evidence Found

$($evidenceLines -join "`n")

## Missing Evidence

$($missingLines -join "`n")

## Academic Context

> **Note**: Academic context uses Semantic Scholar metadata when available. It is useful for literature orientation, but it is not exhaustive validation and does not replace human review. AMiner integration is still planned.

$($academicLines -join "`n")

## Academic Claim Comparison

> **Note**: This comparison is based on retrieved abstracts when available, or metadata only when abstracts/full text are unavailable. It is not a substitute for human literature review.

$($academicComparisonLines -join "`n")

## Cross-Project Comparison

$comparison

## Funding Memory Observations

$($fundingLines -join "`n")

## Risk Flags

$($riskLines -join "`n")

## Suggested Reviewer Questions

$($questionLines -join "`n")

## Human Review Support Status

**$status**
"@

$briefPath = Join-Path $OutDir "$projectIdOut-reviewer-brief.md"
$brief | Set-Content -LiteralPath $briefPath -Encoding UTF8

Write-Host "Reviewer brief written to $briefPath"
