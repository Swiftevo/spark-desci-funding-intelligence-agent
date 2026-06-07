param(
  [string]$CsvPath = "..\desci-funding-data-layer\exports\public\desci_funding_data_layer_latest.csv",
  [string]$OutPath = ".\data\projects.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CsvPath)) {
  Write-Error "CSV file not found: $CsvPath"
}

$rows = Import-Csv -LiteralPath $CsvPath

$projects = foreach ($row in $rows) {
  [ordered]@{
    project_entity_id = $row.project_entity_id
    funding_round_id = $row.funding_round_id
    participation_id = $row.participation_id
    project_name = $row.'Project name'
    link = $row.Link
    round = $row.Round
    season = $row.Season
    status = $row.Status
    region = $row.Region
    project_type = $row.'Project type'
    domain = $row.Domain
    function = $row.Function
    category = $row.Category
    problem_type = $row.'Problem type'
    solution_type = $row.'Solution type'
    target_user = $row.'Target user'
    tags = $row.Tags
    what_are_you_making = $row.'What are you making'
    impact = $row.Impact
    progress = $row.Progress
    why_you = $row.'Why you'
    raw_text = $row.raw_text
    ai_summary = $row.'Summary (AI)'
    desci_alignment = $row.'DeSci alignment'
    evidence_level = $row.'Evidence level'
    narrative_clarity = $row.'Narrative clarity'
    risk_flag = $row.'Risk flag'
    fundability_score = $row.'Fundability score'
    impact_score = $row.'Impact score'
    execution_score = $row.'Execution score'
    raised_amount_usd = $row.raised_amount_usd
    requested_amount_usd = $row.requested_amount_usd
    matching_amount_usd = $row.matching_amount_usd
    donor_count = $row.donor_count
    vote_count = $row.vote_count
    funding_rank = $row.funding_rank
    github_path = $row.'GitHub path'
    obsidian_path = $row.'Obsidian path'
    created = $row.Created
    last_edited = $row.'Last edited'
  }
}

$output = [ordered]@{
  dataset = "Spark DeSci Funding Data Layer"
  source_repo = "https://github.com/Swiftevo/desci-funding-data-layer"
  source_csv = $CsvPath
  imported_at = (Get-Date).ToString("s")
  project_count = $projects.Count
  projects = @($projects)
}

$output | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutPath -Encoding UTF8

Write-Host "Imported $($projects.Count) projects to $OutPath"
