param(
  [string]$ProjectId,
  [string]$ProjectsPath = ".\data\projects.json"
)

$ErrorActionPreference = "Stop"

if (-not $ProjectId) {
  Write-Error "Missing -ProjectId. Example: .\scripts\get-project-detail.ps1 -ProjectId DSPJ-0030"
}

if (-not (Test-Path -LiteralPath $ProjectsPath)) {
  Write-Error "Projects file not found: $ProjectsPath. Run .\scripts\import-spark-data.ps1 first."
}

$dataset = Get-Content -LiteralPath $ProjectsPath -Raw | ConvertFrom-Json
$needle = $ProjectId.ToLowerInvariant()

$project = $dataset.projects | Where-Object {
  ($_.project_entity_id -and $_.project_entity_id.ToLowerInvariant() -eq $needle) -or
  ($_.participation_id -and $_.participation_id.ToLowerInvariant() -eq $needle) -or
  ($_.project_name -and $_.project_name.ToLowerInvariant() -eq $needle)
} | Select-Object -First 1

if (-not $project) {
  Write-Error "Project not found: $ProjectId"
}

$project | ConvertTo-Json -Depth 20
