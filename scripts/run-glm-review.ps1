param(
  [string]$ProjectPath = ".\data\sample_project.json",
  [string]$Model = "glm-5.1",
  [string]$OutPath = ".\review-output.json",
  [switch]$Mock
)

$ErrorActionPreference = "Stop"

if ((-not $Mock) -and (-not $env:ZAI_API_KEY)) {
  Write-Error "Missing ZAI_API_KEY. Set it first: `$env:ZAI_API_KEY='your_api_key'"
}

if (-not (Test-Path -LiteralPath $ProjectPath)) {
  Write-Error "Project file not found: $ProjectPath"
}

$project = Get-Content -LiteralPath $ProjectPath -Raw
$projectObject = $project | ConvertFrom-Json

if ($Mock) {
  $mockReview = @{
    project_name = $projectObject.project_name
    executive_summary = "Mock review for local workflow testing. This project proposes an AI-assisted rare disease diagnosis workflow and requires stronger evidence around benchmark validity, clinical safety, and open-source delivery."
    extracted_claims = $projectObject.claims
    milestone_assessment = @(
      "Prototype milestone is concrete but needs repository and demo evidence.",
      "Benchmark dataset milestone needs dataset construction criteria and evaluation metrics.",
      "Open-source release milestone should include license, documentation, and reproducibility notes."
    )
    evidence_found = @(
      "Project record includes website and GitHub placeholders.",
      "Previous round record reports prototype design and literature review progress."
    )
    missing_evidence = @(
      "No publication or preprint evidence listed.",
      "No real GitHub commit history verified.",
      "No benchmark dataset details provided.",
      "No clinical validation or expert review evidence provided."
    )
    academic_context_queries_for_aminer = @(
      "rare disease AI diagnosis clinical decision support",
      "symptom to disease prediction rare disease literature",
      "AI diagnosis rare disease benchmark dataset"
    )
    funding_memory_observations = @(
      "Project previously requested funding for an initial workflow.",
      "Reported progress is broad and should be checked against concrete artifacts.",
      "Next review should compare promised prototype work against current demo and repository evidence."
    )
    risk_flags = @(
      @{
        risk = "Clinical credibility risk"
        severity = "high"
        reason = "The proposal makes diagnosis-support claims without listed validation evidence."
      },
      @{
        risk = "Evidence continuity risk"
        severity = "medium"
        reason = "Previous round progress is described but not linked to concrete artifacts."
      }
    )
    suggested_reviewer_questions = @(
      "What dataset is used to evaluate symptom-to-disease matching accuracy?",
      "Can the team provide GitHub commits, demo access, and reproducibility instructions?",
      "How does the system avoid unsafe diagnostic recommendations?",
      "Which rare disease databases or literature sources are used for citation grounding?"
    )
    human_review_support_status = "needs_more_evidence"
  } | ConvertTo-Json -Depth 20

  $mockReview | Set-Content -LiteralPath $OutPath -Encoding UTF8
  Write-Host "Mock review written to $OutPath"
  Write-Host $mockReview
  exit 0
}

$systemPrompt = @"
You are Spark DeSci Funding Intelligence Agent, powered by GLM-5.1.

Your role is to assist human reviewers for a DeSci funding round. You do not make final funding decisions. You reduce reviewer workload by producing structured, evidence-aware review support.

Analyze the project through this long-horizon review workflow:
1. Understand the proposal.
2. Extract scientific and operational claims.
3. Identify required evidence.
4. Flag missing evidence.
5. Assess academic context needs.
6. Compare with funding history if available.
7. Generate reviewer questions.

Return strict JSON only.
"@

$userPrompt = @"
Review this Spark DeSci project record:

$project

Return JSON with this schema:
{
  "project_name": string,
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
  temperature = 0.2
  stream = $false
  response_format = @{ type = "json_object" }
} | ConvertTo-Json -Depth 20

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

  Write-Host ""
  Write-Host "Common fixes:"
  Write-Host "1. Wait a minute and retry if this is rate limiting."
  Write-Host "2. Check your Z.AI dashboard quota / billing / model access."
  Write-Host "3. Try a lighter model: .\scripts\run-glm-review.ps1 -Model glm-4.7"
  Write-Host "4. If GLM-5.1 requires a specific enabled plan, confirm it is available for this API key."
  exit 1
}

$content = $response.choices[0].message.content
$content | Set-Content -LiteralPath $OutPath -Encoding UTF8

Write-Host "Review written to $OutPath"
Write-Host $content
