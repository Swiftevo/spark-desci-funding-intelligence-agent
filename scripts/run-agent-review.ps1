param(
  [string]$ProjectId = "DSPJ-0003",
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$Model = "glm-5.1",
  [string]$OutDir = ".\outputs",
  [int]$MaxTurns = 6
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

function Find-Project {
  param([string]$Id)
  $needle = $Id.ToLowerInvariant()
  $dataset.projects | Where-Object {
    ($_.project_entity_id -and $_.project_entity_id.ToLowerInvariant() -eq $needle) -or
    ($_.participation_id -and $_.participation_id.ToLowerInvariant() -eq $needle) -or
    ($_.project_name -and $_.project_name.ToLowerInvariant() -eq $needle)
  } | Select-Object -First 1
}

function Invoke-SearchProjects {
  param([string]$Query, [int]$Top = 5)

  $terms = $Query.ToLowerInvariant().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

  $matches = foreach ($project in $dataset.projects) {
    $score = 0
    $text = @(
      $project.project_name,
      $project.domain,
      $project.what_are_you_making,
      $project.impact,
      $project.progress,
      $project.project_type,
      $project.tags,
      $project.raw_text
    ) -join " "

    $textLower = $text.ToLowerInvariant()

    foreach ($term in $terms) {
      if ($textLower.Contains($term)) {
        $score += 1
      }
    }

    if ($score -gt 0) {
      [ordered]@{
        score = $score
        project_entity_id = $project.project_entity_id
        project_name = $project.project_name
        domain = $project.domain
        project_type = $project.project_type
        what_are_you_making = $project.what_are_you_making
        link = $project.link
      }
    }
  }

  @($matches | Sort-Object -Property { $_.score } -Descending | Select-Object -First $Top)
}

function Compress-Project {
  param($Project, [int]$RawTextLimit = 1200)

  $result = [ordered]@{}
  foreach ($prop in $Project.PSObject.Properties) {
    $val = $prop.Value
    if ($null -ne $val -and $val -ne "") {
      if ($prop.Name -eq "raw_text" -and $val.Length -gt $RawTextLimit) {
        $result[$prop.Name] = $val.Substring(0, $RawTextLimit) + "..."
      } else {
        $result[$prop.Name] = $val
      }
    }
  }
  $result
}

function Invoke-GetProjectDetail {
  param([string]$ProjectId)
  $project = Find-Project -Id $ProjectId
  if (-not $project) {
    return @{ error = "Project not found: $ProjectId" }
  }
  Compress-Project -Project $project
}

function Invoke-CompareProjects {
  param([string[]]$ProjectIds)

  $projects = foreach ($id in $ProjectIds) {
    $p = Find-Project -Id $id
    if ($p) { $p }
  }

  if ($projects.Count -lt 2) {
    return @{ error = "Need at least 2 valid project IDs to compare." }
  }

  $targetProject = $projects | Select-Object -First 1
  $targetDomain = $targetProject.domain
  $dominantComparisonDomain = (@($projects | ForEach-Object { $_.domain } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 1).Name)

  $comparison = foreach ($p in $projects) {
    $compressed = Compress-Project -Project $p
    [ordered]@{
      project_entity_id = $compressed.project_entity_id
      project_name = $compressed.project_name
      domain = $compressed.domain
      project_type = $compressed.project_type
      what_are_you_making = $compressed.what_are_you_making
      impact = $compressed.impact
      progress = $compressed.progress
      evidence_level = $compressed.evidence_level
      risk_flag = $compressed.risk_flag
      fundability_score = $compressed.fundability_score
      github_path = $compressed.github_path
    }
  }

  [ordered]@{
    comparison_count = $comparison.Count
    target_project_id = $targetProject.project_entity_id
    target_domain = $targetDomain
    dominant_comparison_domain = $dominantComparisonDomain
    comparison_note = "dominant_comparison_domain is the most common domain among compared projects; it is not necessarily shared by every project."
    comparison = @($comparison)
  }
}

function Invoke-SearchAcademicContext {
  param([string]$Query)

  $topic = $Query.Trim()

  [ordered]@{
    mode = "dummy_aminer"
    query = $topic
    source = "AMiner placeholder adapter"
    note = "Replace with Semantic Scholar or AMiner API when available."
    field_maturity = if ($topic -match "AI|LLM|Data") { "emerging_to_active" } elseif ($topic -match "Biotech|Health|Bio") { "active_research_area" } else { "needs_literature_check" }
    scientific_context = "Academic context placeholder for '$topic'. Real version will use Semantic Scholar or AMiner for literature search, citation networks, and field maturity analysis."
    credibility_questions = @(
      "What peer-reviewed or preprint literature supports the central claim?",
      "Is the proposed method novel, or mainly an application of known methods?",
      "Are there known limitations, benchmark issues, or reproducibility concerns in this research area?"
    )
  }
}

$tools = @(
  [ordered]@{
    type = "function"
    function = [ordered]@{
      name = "search_projects"
      description = "Search the Spark DeSci 49-project dataset by keywords. Returns ranked matching projects with basic info. Use this to find projects by domain, topic, or name."
      parameters = [ordered]@{
        type = "object"
        properties = [ordered]@{
          query = [ordered]@{
            type = "string"
            description = "Search keywords, e.g. 'AI funding', 'biotech health', 'decentralized science'"
          }
          top = [ordered]@{
            type = "integer"
            description = "Number of results to return (default 5)"
          }
        }
        required = @("query")
      }
    }
  }
  [ordered]@{
    type = "function"
    function = [ordered]@{
      name = "get_project_detail"
      description = "Get full details of a Spark DeSci project by its project_entity_id (e.g. DSPJ-0003). Returns all project fields including raw proposal text."
      parameters = [ordered]@{
        type = "object"
        properties = [ordered]@{
          project_id = [ordered]@{
            type = "string"
            description = "Project entity ID, e.g. DSPJ-0003"
          }
        }
        required = @("project_id")
      }
    }
  }
  [ordered]@{
    type = "function"
    function = [ordered]@{
      name = "compare_projects"
      description = "Compare two or more Spark DeSci projects side by side. Returns structured comparison including domain, claims, evidence level, and risk flags. Use this to identify overlap, complementarity, or relative strength."
      parameters = [ordered]@{
        type = "object"
        properties = [ordered]@{
          project_ids = [ordered]@{
            type = "array"
            items = @{ type = "string" }
            description = "Array of project entity IDs to compare, e.g. ['DSPJ-0003', 'DSPJ-0030']"
          }
        }
        required = @("project_ids")
      }
    }
  }
  [ordered]@{
    type = "function"
    function = [ordered]@{
      name = "search_academic_context"
      description = "Search academic literature context for a topic. Returns field maturity, scientific context, and credibility questions. Currently uses placeholder data; will be replaced with Semantic Scholar or AMiner API."
      parameters = [ordered]@{
        type = "object"
        properties = [ordered]@{
          query = [ordered]@{
            type = "string"
            description = "Academic search query, e.g. 'LLM-based evaluation system for funding proposals'"
          }
        }
        required = @("query")
      }
    }
  }
)

$systemPrompt = @"
You are Spark DeSci Funding Intelligence Agent, powered by GLM-5.1.

You assist human reviewers for a DeSci funding round. You do NOT make final funding decisions. Your job is to reduce reviewer workload by producing structured, evidence-aware review support.

Your workflow:
1. First, get the full project detail using get_project_detail.
2. Search for similar or related projects using search_projects to enable cross-project comparison.
3. Compare the target project with related projects using compare_projects.
4. Search academic context for the project's domain and key claims using search_academic_context.
5. Synthesize all gathered evidence into a final structured review.

You MUST call tools to gather information before producing your review. Do not guess or fabricate evidence.
After gathering sufficient information, produce your final review as a JSON object with this exact schema:

{
  "mode": "agent-glm-5.1",
  "project_entity_id": "DSPJ-XXXX",
  "participation_id": "DSPT-XXXXX",
  "project_name": "...",
  "executive_summary": "...",
  "extracted_claims": ["..."],
  "milestone_assessment": ["..."],
  "evidence_found": ["..."],
  "missing_evidence": ["..."],
  "academic_context_queries_for_aminer": ["..."],
  "academic_context_results": ["..."],
  "cross_project_comparison": "...",
  "funding_memory_observations": ["..."],
  "risk_flags": [
    {
      "risk": "...",
      "severity": "low|medium|high",
      "reason": "..."
    }
  ],
  "suggested_reviewer_questions": ["..."],
  "human_review_support_status": "ready_for_review|needs_more_evidence|high_risk_claims"
}

Return ONLY this JSON object as your final response. No additional text.
"@

$userPrompt = "Review Spark DeSci project: $ProjectId"

$messages = [System.Collections.ArrayList]::new()
[void]$messages.Add([ordered]@{ role = "system"; content = $systemPrompt })
[void]$messages.Add([ordered]@{ role = "user"; content = $userPrompt })

$traceEntries = [System.Collections.ArrayList]::new()
$turn = 0
$finalReview = $null

Write-Host "=== Agent Review Start: $ProjectId ===" -ForegroundColor Cyan

while ($turn -lt $MaxTurns) {
  $turn++
  Write-Host "`n--- Turn $turn ---" -ForegroundColor Yellow

  $body = @{
    model = $Model
    messages = @($messages)
    tools = @($tools)
    tool_choice = "auto"
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
    Write-Host "API call failed at turn $turn" -ForegroundColor Red
    if ($_.Exception.Response) {
      $stream = $_.Exception.Response.GetResponseStream()
      if ($stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error: $errorBody" -ForegroundColor Red
      }
    } else {
      Write-Host $_.Exception.Message -ForegroundColor Red
    }
    break
  }

  $choice = $response.choices[0]
  $message = $choice.message

  [void]$messages.Add($message)

  if ($message.tool_calls -and $message.tool_calls.Count -gt 0) {
    foreach ($toolCall in $message.tool_calls) {
      $fnName = $toolCall.function.name
      $fnArgs = $toolCall.function.arguments
      $toolCallId = $toolCall.id

      Write-Host "  Tool call: $fnName($fnArgs)" -ForegroundColor Green

      [void]$traceEntries.Add([ordered]@{
        turn = $turn
        type = "tool_call"
        tool = $fnName
        arguments = $fnArgs
        tool_call_id = $toolCallId
      })

      $parsedArgs = $fnArgs | ConvertFrom-Json
      $toolResult = $null

      switch ($fnName) {
        "search_projects" {
          $top = if ($parsedArgs.top) { [int]$parsedArgs.top } else { 5 }
          $toolResult = Invoke-SearchProjects -Query $parsedArgs.query -Top $top
        }
        "get_project_detail" {
          $toolResult = Invoke-GetProjectDetail -ProjectId $parsedArgs.project_id
        }
        "compare_projects" {
          $ids = @($parsedArgs.project_ids)
          $toolResult = Invoke-CompareProjects -ProjectIds $ids
        }
        "search_academic_context" {
          $toolResult = Invoke-SearchAcademicContext -Query $parsedArgs.query
        }
        default {
          $toolResult = @{ error = "Unknown tool: $fnName" }
        }
      }

      $resultJson = $toolResult | ConvertTo-Json -Depth 20 -Compress

      Write-Host "  Result: $($resultJson.Substring(0, [Math]::Min(200, $resultJson.Length)))..." -ForegroundColor Gray

      [void]$traceEntries.Add([ordered]@{
        turn = $turn
        type = "tool_result"
        tool = $fnName
        tool_call_id = $toolCallId
        result_preview = $resultJson.Substring(0, [Math]::Min(500, $resultJson.Length))
      })

      [void]$messages.Add([ordered]@{
        role = "tool"
        content = $resultJson
        tool_call_id = $toolCallId
      })
    }
  } else {
    $content = $message.content
    Write-Host "  Agent produced final output." -ForegroundColor Cyan

    [void]$traceEntries.Add([ordered]@{
      turn = $turn
      type = "final_response"
      content_preview = $content.Substring(0, [Math]::Min(500, $content.Length))
    })

    $finalReview = $content
    break
  }
}

if (-not $finalReview) {
  Write-Host "`nAgent did not produce final review within $MaxTurns turns." -ForegroundColor Red
  exit 1
}

$reviewObject = $finalReview | ConvertFrom-Json
$projectId = if ($reviewObject.project_entity_id) { $reviewObject.project_entity_id } else { $ProjectId }

$reviewPath = Join-Path $OutDir "$projectId-agent-review.json"
$tracePath = Join-Path $OutDir "$projectId-agent-trace.json"

$finalReview | Set-Content -LiteralPath $reviewPath -Encoding UTF8

$traceOutput = [ordered]@{
  project_id = $ProjectId
  model = $Model
  total_turns = $turn
  trace = @($traceEntries)
}
$traceOutput | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $tracePath -Encoding UTF8

Write-Host "`n=== Agent Review Complete ===" -ForegroundColor Cyan
Write-Host "Review: $reviewPath"
Write-Host "Trace:  $tracePath"
