param(
  [string]$ProjectId = "DSPJ-0003",
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$Model = "glm-5.1",
  [string]$OutDir = ".\outputs"
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
$needle = $ProjectId.ToLowerInvariant()

$project = $dataset.projects | Where-Object {
  ($_.project_entity_id -and $_.project_entity_id.ToLowerInvariant() -eq $needle) -or
  ($_.participation_id -and $_.participation_id.ToLowerInvariant() -eq $needle) -or
  ($_.project_name -and $_.project_name.ToLowerInvariant() -eq $needle)
} | Select-Object -First 1

if (-not $project) {
  Write-Error "Project not found: $ProjectId"
}

$projectJson = $project | ConvertTo-Json -Depth 20
$outPath = Join-Path $OutDir "$($project.project_entity_id)-glm-review.json"

$systemPrompt = @"
You are Spark DeSci Funding Intelligence Agent, powered by GLM-5.1.

You assist human reviewers for a DeSci funding round. You do not make final funding decisions. Your job is to reduce reviewer workload by producing structured, evidence-aware review support.

Use this long-horizon workflow:
1. Understand the proposal.
2. Extract scientific, operational, and funding claims.
3. Identify evidence already present in the Spark database.
4. Flag missing evidence.
5. Propose AMiner academic context searches.
6. Identify funding-memory observations.
7. Generate reviewer questions.

Return strict JSON only.
"@

$userPrompt = @"
Review this Spark DeSci project record:

$projectJson

Return JSON with this schema:
{
  "mode": "glm-5.1",
  "project_name": string,
  "project_entity_id": string,
  "participation_id": string,
  "executive_summary": string,
  "extracted_claims": string[],
  "milestone_assessment": string[],
  "evidence_found": string[],
  "missing_evidence": string[],
  "academic_context_queries_for_aminer": string[],
  "funding_memory_observations": string[],
  "risk_flags": [
    {
      "risk": string,
      "severity": "low" | "medium" | "high",
      "reason": string
    }
  ],
  "suggested_reviewer_questions": string[],
  "human_review_support_status": "ready_for_review" | "needs_more_evidence" | "high_risk_claims"
}
"@

$body = @{
  model = $Model
  messages = @(
    @{ role = "system"; content = $systemPrompt },
    @{ role = "user"; content = $userPrompt }
  )
  thinking = @{ type = "enabled" }
  max_tokens = 4096
  temperature = 0.2
  stream = $false
  response_format = @{ type = "json_object" }
} | ConvertTo-Json -Depth 30

$headers = @{
  "Authorization" = "Bearer $env:ZAI_API_KEY"
  "Content-Type" = "application/json"
}

try {
  $response = Invoke-RestMethod `
    -Uri "https://api.z.ai/api/paas/v4/chat/completions" `
    -Method Post `
    -Headers $headers `
    -Body $body
} catch {
  Write-Host "Z.AI request failed." -ForegroundColor Red
  Write-Host "Model: $Model"

  if ($_.Exception.Response) {
    Write-Host "HTTP status: $([int]$_.Exception.Response.StatusCode) $($_.Exception.Response.StatusDescription)"

    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
      $reader = New-Object System.IO.StreamReader($stream)
      $errorBody = $reader.ReadToEnd()
      if ($errorBody) {
        Write-Host "Response body:"
        Write-Host $errorBody
      }
    }
  } else {
    Write-Host $_.Exception.Message
  }

  exit 1
}

$content = $response.choices[0].message.content
$content | Set-Content -LiteralPath $outPath -Encoding UTF8

Write-Host "GLM review written to $outPath"
Write-Host $content
