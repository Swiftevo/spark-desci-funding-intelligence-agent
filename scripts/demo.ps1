param(
  [string]$ProjectId = "DSPJ-0003",
  [int]$BatchSize = 0,
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$OutDir = ".\outputs",
  [switch]$SkipImport
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Spark DeSci Funding Intelligence Agent" -ForegroundColor Cyan
Write-Host "One-Click Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $env:ZAI_API_KEY) {
  Write-Host "[ERROR] Missing ZAI_API_KEY environment variable." -ForegroundColor Red
  Write-Host "Set it first:" -ForegroundColor Yellow
  Write-Host '  $env:ZAI_API_KEY="your_api_key"' -ForegroundColor Yellow
  exit 1
}

if (-not $SkipImport) {
  Write-Host "[Step 1/4] Importing Spark DeSci project data..." -ForegroundColor Yellow
  if (Test-Path -LiteralPath $ProjectsPath) {
    Write-Host "  Projects file already exists: $ProjectsPath" -ForegroundColor Gray
    $dataset = Get-Content -LiteralPath $ProjectsPath -Raw | ConvertFrom-Json
    Write-Host "  Loaded $($dataset.projects.Count) projects" -ForegroundColor Gray
  } else {
    try {
      & "$PSScriptRoot\import-spark-data.ps1"
      Write-Host "  Import complete." -ForegroundColor Green
    } catch {
      Write-Host "  [ERROR] Import failed: $($_.Exception.Message)" -ForegroundColor Red
      exit 1
    }
  }
} else {
  Write-Host "[Step 1/4] Skipping import (SkipImport flag set)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[Step 2/4] Running GLM-5.1 agent review for project: $ProjectId" -ForegroundColor Yellow
Write-Host "  This demonstrates long-horizon task execution with autonomous tool calling." -ForegroundColor Gray
Write-Host ""

$reviewStartTime = Get-Date

try {
  & "$PSScriptRoot\run-agent-review.ps1" `
    -ProjectId $ProjectId `
    -ProjectsPath $ProjectsPath `
    -OutDir $OutDir
} catch {
  Write-Host ""
  Write-Host "  [ERROR] Agent review failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "  This may be due to API quota exhaustion or network issues." -ForegroundColor Yellow
  Write-Host "  You can still view cached outputs if available." -ForegroundColor Yellow
}

$reviewEndTime = Get-Date
$reviewDuration = ($reviewEndTime - $reviewStartTime).TotalSeconds

Write-Host ""
Write-Host "[Step 3/4] Generating reviewer brief..." -ForegroundColor Yellow

try {
  & "$PSScriptRoot\generate-reviewer-brief.ps1" -ProjectId $ProjectId -OutDir $OutDir
  Write-Host "  Brief generated." -ForegroundColor Green
} catch {
  Write-Host "  [WARNING] Brief generation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[Step 4/4] Summary" -ForegroundColor Yellow

$reviewPath = Join-Path $OutDir "$ProjectId-agent-review.json"
$tracePath = Join-Path $OutDir "$ProjectId-agent-trace.json"
$briefPath = Join-Path $OutDir "$ProjectId-reviewer-brief.md"

if (Test-Path -LiteralPath $reviewPath) {
  $review = Get-Content -LiteralPath $reviewPath -Raw | ConvertFrom-Json
  Write-Host ""
  Write-Host "  Project:     $($review.project_name)" -ForegroundColor Cyan
  Write-Host "  Project ID:  $ProjectId" -ForegroundColor Gray
  Write-Host "  Status:      $($review.human_review_support_status)" -ForegroundColor Gray
  Write-Host "  Risk Flags:  $($review.risk_flags.Count)" -ForegroundColor Gray
  Write-Host "  Duration:    $([int]$reviewDuration)s" -ForegroundColor Gray
}

if (Test-Path -LiteralPath $tracePath) {
  $trace = Get-Content -LiteralPath $tracePath -Raw | ConvertFrom-Json
  Write-Host "  Turns:       $($trace.total_turns)" -ForegroundColor Gray

  $toolCalls = $trace.trace | Where-Object { $_.type -eq "tool_call" }
  Write-Host "  Tool Calls: $($toolCalls.Count)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Output Files:" -ForegroundColor Gray
if (Test-Path -LiteralPath $reviewPath) {
  Write-Host "    - $reviewPath" -ForegroundColor Gray
}
if (Test-Path -LiteralPath $tracePath) {
  Write-Host "    - $tracePath" -ForegroundColor Gray
}
if (Test-Path -LiteralPath $briefPath) {
  Write-Host "    - $briefPath" -ForegroundColor Gray
}

if ($BatchSize -gt 0) {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "Batch Review: $BatchSize projects" -ForegroundColor Cyan
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host ""

  try {
    & "$PSScriptRoot\run-batch-review.ps1" -SampleSize $BatchSize -ProjectsPath $ProjectsPath -OutDir $OutDir
  } catch {
    Write-Host "[ERROR] Batch review failed: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Demo Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - View reviewer brief: cat $briefPath" -ForegroundColor Gray
Write-Host "  - View agent trace:   cat $tracePath" -ForegroundColor Gray
Write-Host "  - Run another demo:   .\scripts\demo.ps1 -ProjectId DSPJ-0006" -ForegroundColor Gray
Write-Host ""
Write-Host "Demo Caveats:" -ForegroundColor Yellow
Write-Host "  - Academic context uses Semantic Scholar metadata, but is not exhaustive validation" -ForegroundColor Gray
Write-Host "  - AMiner integration is still planned, not live" -ForegroundColor Gray
Write-Host "  - Agent assists reviewers but does not make funding decisions" -ForegroundColor Gray
Write-Host ""
