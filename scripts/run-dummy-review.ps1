param(
  [string]$ProjectId = "DSPJ-0001",
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$OutPath = ".\review-output.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ProjectsPath)) {
  Write-Error "Projects file not found: $ProjectsPath. Run .\scripts\import-spark-data.ps1 first."
}

$dataset = Get-Content -LiteralPath $ProjectsPath -Raw | ConvertFrom-Json
$project = $dataset.projects | Where-Object {
  $_.project_entity_id -eq $ProjectId -or $_.participation_id -eq $ProjectId -or $_.project_name -eq $ProjectId
} | Select-Object -First 1

if (-not $project) {
  Write-Error "Project not found: $ProjectId"
}

$projectName = $project.PSObject.Properties["project_name"].Value
$projectType = $project.PSObject.Properties["project_type"].Value
$domain = $project.PSObject.Properties["domain"].Value
$what = $project.PSObject.Properties["what_are_you_making"].Value
$impact = $project.PSObject.Properties["impact"].Value
$progress = $project.PSObject.Properties["progress"].Value
$link = $project.PSObject.Properties["link"].Value
$rawText = $project.PSObject.Properties["raw_text"].Value
$githubPath = $project.PSObject.Properties["github_path"].Value
$evidenceLevel = $project.PSObject.Properties["evidence_level"].Value
$desciAlignment = $project.PSObject.Properties["desci_alignment"].Value

$academicQueries = @()
foreach ($part in @($domain, $what, $impact)) {
  if ($part) {
    $academicQueries += $part
  }
}

$missingEvidence = New-Object System.Collections.Generic.List[string]
if (-not $githubPath) { $missingEvidence.Add("No GitHub path is recorded in the Spark database.") }
if (-not $evidenceLevel) { $missingEvidence.Add("Evidence level has not been scored yet.") }
if (-not $desciAlignment) { $missingEvidence.Add("DeSci alignment score is missing.") }
if (-not $rawText) { $missingEvidence.Add("Raw proposal text is missing.") }
if ($rawText -and $rawText.Length -lt 600) { $missingEvidence.Add("Proposal text is short and may need additional supporting evidence.") }

$riskFlags = New-Object System.Collections.Generic.List[object]
if (-not $progress) {
  $riskFlags.Add([ordered]@{
    risk = "Progress evidence gap"
    severity = "medium"
    reason = "The project record does not include a clear progress statement."
  })
}
if (-not $githubPath) {
  $riskFlags.Add([ordered]@{
    risk = "Artifact verification gap"
    severity = "medium"
    reason = "No GitHub or repository path is available for artifact verification."
  })
}
if (($domain -match "Biotech|Health|AI|Data") -and (-not $evidenceLevel)) {
  $riskFlags.Add([ordered]@{
    risk = "Scientific validation gap"
    severity = "high"
    reason = "The project is in a research-sensitive domain but has no recorded evidence level."
  })
}

$missingEvidenceItems = @($missingEvidence.ToArray())
$riskFlagItems = @($riskFlags.ToArray())

$review = [ordered]@{
  mode = "dummy"
  project_name = $projectName
  project_entity_id = $project.project_entity_id
  participation_id = $project.participation_id
  executive_summary = "Dummy reviewer output for workflow testing. $projectName is a $projectType project in $domain. It proposes: $what"
  extracted_claims = (@($what, $impact, $progress) | Where-Object { $_ })
  milestone_assessment = @(
    "Review whether the stated progress maps to concrete artifacts.",
    "Check whether the project has public outputs that can be verified before the next funding round.",
    "Compare the proposal against similar Spark DeSci projects in the same domain."
  )
  evidence_found = @(
    "Spark project record exists in the 49-project dataset.",
    "Raw proposal text is preserved for reviewer and agent analysis.",
    "Artizen proposal link is available: $link"
  )
  missing_evidence = $missingEvidenceItems
  academic_context_queries_for_aminer = (@("$domain $what", "$domain decentralized science funding", "$what literature review") | Where-Object { $_ -and $_.Trim() })
  funding_memory_observations = @(
    "This dataset currently contains Artizen Season 6 participation metadata.",
    "Cross-round memory is ready to extend once additional Spark or Gitcoin DeSci rounds are imported.",
    "Stable IDs allow future comparison across funding rounds."
  )
  risk_flags = $riskFlagItems
  suggested_reviewer_questions = @(
    "What concrete artifacts prove the stated progress?",
    "What evidence should reviewers inspect before approving this project for the next round?",
    "Which scientific or ecosystem claims need AMiner-backed context?",
    "How does this project compare with other Spark DeSci projects in the same domain?"
  )
  human_review_support_status = if ($riskFlagItems.Count -gt 0) { "needs_more_evidence" } else { "ready_for_review" }
}

$review | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutPath -Encoding UTF8

Write-Host "Dummy review written to $OutPath"
$review | ConvertTo-Json -Depth 20
