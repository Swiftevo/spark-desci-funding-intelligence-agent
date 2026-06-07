param(
  [int]$SampleSize = 5,
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$Model = "glm-5.1",
  [string]$OutDir = ".\outputs",
  [int]$MaxTurns = 12,
  [int]$DelaySeconds = 3
)

$ErrorActionPreference = "Stop"

if (-not $env:ZAI_API_KEY) {
  Write-Error "Missing ZAI_API_KEY. Set it first: `$env:ZAI_API_KEY='your_api_key'"
}

if (-not (Test-Path -LiteralPath $ProjectsPath)) {
  Write-Error "Projects file not found: $ProjectsPath. Run .\scripts\import-spark-data.ps1 first."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$dataset = Get-Content -LiteralPath $ProjectsPath -Raw | ConvertFrom-Json
$totalProjects = $dataset.projects.Count

if ($SampleSize -gt $totalProjects) {
  $SampleSize = $totalProjects
}

$indices = New-Object System.Collections.ArrayList
while ($indices.Count -lt $SampleSize) {
  $candidate = Get-Random -Minimum 0 -Maximum $totalProjects
  if (-not $indices.Contains($candidate)) {
    [void]$indices.Add($candidate)
  }
}

$selectedProjects = foreach ($idx in $indices) {
  $dataset.projects[$idx]
}

Write-Host "=== Batch Review: $SampleSize of $totalProjects projects ===" -ForegroundColor Cyan
foreach ($p in $selectedProjects) {
  Write-Host "  - $($p.project_entity_id): $($p.project_name)" -ForegroundColor Gray
}
Write-Host ""

$summaryEntries = [System.Collections.ArrayList]::new()
$successCount = 0
$failCount = 0
$current = 0

foreach ($project in $selectedProjects) {
  $current++
  $projectId = $project.project_entity_id
  $projectName = $project.project_name

  Write-Host "[$current/$SampleSize] Reviewing: $projectId - $projectName" -ForegroundColor Yellow

  try {
    $output = & "$PSScriptRoot\run-agent-review.ps1" `
      -ProjectId $projectId `
      -ProjectsPath $ProjectsPath `
      -Model $Model `
      -OutDir $OutDir `
      -MaxTurns $MaxTurns 2>&1

    $reviewPath = Join-Path $OutDir "$projectId-agent-review.json"
    $tracePath = Join-Path $OutDir "$projectId-agent-trace.json"

    $reviewExists = Test-Path -LiteralPath $reviewPath
    $traceExists = Test-Path -LiteralPath $tracePath

    if ($reviewExists) {
      $review = Get-Content -LiteralPath $reviewPath -Raw | ConvertFrom-Json
      $status = $review.human_review_support_status
      $riskCount = $review.risk_flags.Count

      [void]$summaryEntries.Add([ordered]@{
        project_entity_id = $projectId
        project_name = $projectName
        domain = $project.domain
        status = $status
        risk_count = $riskCount
        review_path = $reviewPath
        trace_path = $tracePath
        error = $null
      })

      $successCount++
      Write-Host "  Done. Status: $status, Risks: $riskCount" -ForegroundColor Green
    } else {
      [void]$summaryEntries.Add([ordered]@{
        project_entity_id = $projectId
        project_name = $projectName
        domain = $project.domain
        status = "error"
        risk_count = 0
        review_path = $null
        trace_path = $null
        error = "Review file not created"
      })
      $failCount++
      Write-Host "  Failed: Review file not created" -ForegroundColor Red
    }
  } catch {
    [void]$summaryEntries.Add([ordered]@{
      project_entity_id = $projectId
      project_name = $projectName
      domain = $project.domain
      status = "error"
      risk_count = 0
      review_path = $null
      trace_path = $null
      error = $_.Exception.Message
    })
    $failCount++
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
  }

  if ($current -lt $SampleSize) {
    Write-Host "  Waiting $DelaySeconds seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds $DelaySeconds
  }
}

$summary = [ordered]@{
  batch_date = (Get-Date).ToString("s")
  sample_size = $SampleSize
  total_projects = $totalProjects
  success_count = $successCount
  fail_count = $failCount
  model = $Model
  results = @($summaryEntries)
}

$summaryPath = Join-Path $OutDir "batch-summary.json"
$summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "=== Batch Review Complete ===" -ForegroundColor Cyan
Write-Host "Success: $successCount / $SampleSize"
Write-Host "Failed:  $failCount / $SampleSize"
Write-Host "Summary: $summaryPath"
