param(
  [string]$ProjectId = "DSPJ-0003",
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$OutDir = ".\outputs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ProjectsPath)) {
  Write-Error "Projects file not found: $ProjectsPath. Run .\scripts\import-spark-data.ps1 first."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$reviewPath = Join-Path $OutDir "$ProjectId-review.json"
$aminerPath = Join-Path $OutDir "$ProjectId-aminer-context.json"
$briefPath = Join-Path $OutDir "$ProjectId-reviewer-brief.md"

& "$PSScriptRoot\run-dummy-review.ps1" -ProjectId $ProjectId -ProjectsPath $ProjectsPath -OutPath $reviewPath | Out-Null
$review = Get-Content -LiteralPath $reviewPath -Raw | ConvertFrom-Json

$firstQuery = $review.academic_context_queries_for_aminer | Select-Object -First 1
& "$PSScriptRoot\search-aminer-context.ps1" -Query $firstQuery -OutPath $aminerPath | Out-Null
$aminer = Get-Content -LiteralPath $aminerPath -Raw | ConvertFrom-Json

$riskLines = foreach ($risk in $review.risk_flags) {
  "- [$($risk.severity)] $($risk.risk): $($risk.reason)"
}

$missingLines = foreach ($item in $review.missing_evidence) {
  "- $item"
}

$questionLines = foreach ($item in $review.suggested_reviewer_questions) {
  "- $item"
}

$claimLines = foreach ($item in $review.extracted_claims) {
  "- $item"
}

$evidenceLines = foreach ($item in $review.evidence_found) {
  "- $item"
}

$brief = @"
# Spark DeSci Reviewer Brief

Project: $($review.project_name)
Project ID: $($review.project_entity_id)
Participation ID: $($review.participation_id)
Mode: Dummy workflow, ready for GLM-5.1 replacement

## Executive Summary

$($review.executive_summary)

## Extracted Claims

$($claimLines -join "`n")

## Evidence Found

$($evidenceLines -join "`n")

## Missing Evidence

$($missingLines -join "`n")

## AMiner Academic Context

Query: $($aminer.query)

$($aminer.scientific_context)

Field maturity: $($aminer.field_maturity)

## Risk Flags

$($riskLines -join "`n")

## Suggested Reviewer Questions

$($questionLines -join "`n")

## Human Review Support Status

$($review.human_review_support_status)
"@

$brief | Set-Content -LiteralPath $briefPath -Encoding UTF8

Write-Host "Workflow complete."
Write-Host "Review JSON: $reviewPath"
Write-Host "AMiner context JSON: $aminerPath"
Write-Host "Reviewer brief: $briefPath"
