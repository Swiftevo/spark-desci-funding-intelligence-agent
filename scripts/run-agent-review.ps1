param(
  [string]$ProjectId = "DSPJ-0003",
  [string]$ProjectsPath = ".\data\projects.json",
  [string]$Model = "glm-5.1",
  [string]$OutDir = ".\outputs",
  [int]$MaxTurns = 6,
  [int]$MaxRetries = 2
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
  $encodedQuery = [Uri]::EscapeDataString($topic)

  $semanticScholarFields = "title,abstract,authors,year,citationCount,influentialCitationCount,fieldsOfStudy,publicationVenue,openAccessPdf,externalIds,url"
  $semanticScholarUri = "https://api.semanticscholar.org/graph/v1/paper/search?query=$encodedQuery&fields=$semanticScholarFields&limit=5"

  $headers = @{}
  if ($env:SEMANTIC_SCHOLAR_API_KEY) {
    $headers["x-api-key"] = $env:SEMANTIC_SCHOLAR_API_KEY
  }

  $useOpenAlexFallback = $false
  $fallbackReason = $null

  try {
    $response = Invoke-RestMethod -Uri $semanticScholarUri -Method Get -Headers $headers -TimeoutSec 30
  } catch {
    $errorMessage = $_.Exception.Message
    if ($errorMessage -match "429") {
      $useOpenAlexFallback = $true
      $fallbackReason = "Semantic Scholar rate limit (429). Falling back to OpenAlex."
    } else {
      $useOpenAlexFallback = $true
      $fallbackReason = "Semantic Scholar error: $errorMessage. Falling back to OpenAlex."
    }
  }

  if ($useOpenAlexFallback) {
    Write-Host "  Fallback: $fallbackReason" -ForegroundColor Yellow
    $openAlexUri = "https://api.openalex.org/works?search=$encodedQuery&per_page=5"
    if ($env:OPENALEX_API_KEY) {
      $openAlexUri += "&api_key=$($env:OPENALEX_API_KEY)"
    }

    try {
      $openAlexResponse = Invoke-RestMethod -Uri $openAlexUri -Method Get -TimeoutSec 30
      return Process-OpenAlexResponse -Response $openAlexResponse -Topic $topic -FallbackReason $fallbackReason
    } catch {
      return @{
        mode = "openalex_fallback_failed"
        query = $topic
        source = "OpenAlex API (fallback)"
        error = "Both Semantic Scholar and OpenAlex failed. Semantic Scholar: $fallbackReason. OpenAlex: $($_.Exception.Message)"
        field_maturity = "needs_verification"
        scientific_context = "Failed to retrieve academic data for '$topic' from both sources."
        credibility_questions = @(
          "What peer-reviewed or preprint literature supports the central claim?",
          "Is the proposed method novel, or mainly an application of known methods?"
        )
      }
    }
  }

  $papers = @()
  $fieldCounts = @{}

  if ($response.data -and $response.data.Count -gt 0) {
    foreach ($paper in $response.data) {
      $fieldsOfStudy = @($paper.fieldsOfStudy)
      foreach ($field in $fieldsOfStudy) {
        if ($field) {
          if ($fieldCounts.ContainsKey($field)) {
            $fieldCounts[$field] = $fieldCounts[$field] + 1
          } else {
            $fieldCounts[$field] = 1
          }
        }
      }

      $authorNames = @($paper.authors | ForEach-Object { $_.name } | Where-Object { $_ })

      $pdfUrl = $null
      if ($paper.openAccessPdf -and $paper.openAccessPdf.url) { $pdfUrl = $paper.openAccessPdf.url }

      $doi = $null
      if ($paper.externalIds -and $paper.externalIds.DOI) { $doi = $paper.externalIds.DOI }

      $venueName = $null
      if ($paper.publicationVenue -and $paper.publicationVenue.name) { $venueName = $paper.publicationVenue.name }
      elseif ($paper.venue) { $venueName = $paper.venue }

      $abstractPreview = $null
      if ($paper.abstract) {
        $abstractPreview = $paper.abstract.Substring(0, [Math]::Min(300, $paper.abstract.Length))
        if ($paper.abstract.Length -gt 300) { $abstractPreview += "..." }
      }

      $papers += [ordered]@{
        title = $paper.title
        year = $paper.year
        authors = $authorNames
        venue = $venueName
        citationCount = if ($null -ne $paper.citationCount) { $paper.citationCount } else { 0 }
        influentialCitationCount = if ($null -ne $paper.influentialCitationCount) { $paper.influentialCitationCount } else { 0 }
        fieldsOfStudy = $fieldsOfStudy
        abstract_preview = $abstractPreview
        openAccessPdf = $pdfUrl
        doi = $doi
        url = $paper.url
      }
    }
  }

  $totalPapers = $response.total
  $topFields = $fieldCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3 | ForEach-Object { $_.Key }

  $avgCitations = 0
  if ($papers.Count -gt 0) {
    $avgCitations = [Math]::Round(($papers | ForEach-Object { $_.citationCount } | Measure-Object -Average).Average, 1)
  }

  $recentPapers = @($papers | Where-Object { $_.year -and $_.year -ge 2023 })
  $recentRatio = if ($papers.Count -gt 0) { [Math]::Round($recentPapers.Count / $papers.Count * 100, 0) } else { 0 }

  $fieldMaturity = "needs_literature_check"
  if ($totalPapers -gt 1000 -and $avgCitations -gt 50) {
    $fieldMaturity = "established_research_area"
  } elseif ($totalPapers -gt 100 -or $recentRatio -gt 60) {
    $fieldMaturity = "active_research_area"
  } elseif ($totalPapers -gt 10) {
    $fieldMaturity = "emerging_research_area"
  }

  $highCitationPapers = @($papers | Where-Object { $_.citationCount -gt 100 } | Select-Object -First 3)

  $credibilityQuestions = @(
    "What peer-reviewed or preprint literature supports the central claim?",
    "Is the proposed method novel, or mainly an application of known methods?"
  )

  if ($highCitationPapers.Count -gt 0) {
    $credibilityQuestions += "Do the high-citation papers ($($highCitationPapers.Count) found) support or contradict the project's claims?"
  }

  if ($recentRatio -gt 70) {
    $credibilityQuestions += "This is a rapidly evolving field ($recentRatio% papers from 2023+). Are the project's methods current with the latest research?"
  }

  $scientificContext = "Semantic Scholar found $totalPapers papers for '$topic'. "
  $scientificContext += "Top fields: $($topFields -join ', '). "
  $scientificContext += "Average citations: $avgCitations. "

  if ($fieldMaturity -eq "established_research_area") {
    $scientificContext += "This is an established research area with substantial prior work."
  } elseif ($fieldMaturity -eq "active_research_area") {
    $scientificContext += "This is an active research area with ongoing publications."
  } elseif ($fieldMaturity -eq "emerging_research_area") {
    $scientificContext += "This is an emerging research area with limited prior work."
  } else {
    $scientificContext += "Limited literature found. Manual literature review recommended."
  }

  [ordered]@{
    mode = "semantic_scholar"
    query = $topic
    source = "Semantic Scholar API"
    total_papers_found = $totalPapers
    papers_returned = $papers.Count
    papers = $papers
    field_maturity = $fieldMaturity
    top_fields = $topFields
    average_citations = $avgCitations
    recent_paper_ratio = $recentRatio
    high_citation_papers_count = $highCitationPapers.Count
    scientific_context = $scientificContext
    credibility_questions = $credibilityQuestions
  }
}

function Process-OpenAlexResponse {
  param($Response, [string]$Topic, [string]$FallbackReason)

  $papers = @()
  $fieldCounts = @{}

  if ($Response.results -and $Response.results.Count -gt 0) {
    foreach ($work in $Response.results) {
      $topics = @()
      if ($work.topics) {
        $topics = @($work.topics | ForEach-Object { $_.display_name } | Where-Object { $_ } | Select-Object -First 3)
        foreach ($topicName in $topics) {
          if ($fieldCounts.ContainsKey($topicName)) {
            $fieldCounts[$topicName] = $fieldCounts[$topicName] + 1
          } else {
            $fieldCounts[$topicName] = 1
          }
        }
      }

      $authorNames = @()
      if ($work.authorships) {
        $authorNames = @($work.authorships | ForEach-Object { $_.author.display_name } | Where-Object { $_ } | Select-Object -First 5)
      }

      $venueName = $null
      if ($work.primary_location -and $work.primary_location.source) {
        $venueName = $work.primary_location.source.display_name
      }

      $doi = $null
      if ($work.doi) {
        $doi = $work.doi -replace "^https://doi.org/", ""
      }

      $openAccessUrl = $null
      if ($work.open_access -and $work.open_access.oa_url) {
        $openAccessUrl = $work.open_access.oa_url
      }

      $abstract = $null
      if ($work.abstract_inverted_index) {
        $tokens = @()
        foreach ($property in $work.abstract_inverted_index.PSObject.Properties) {
          foreach ($position in @($property.Value)) {
            $tokens += [pscustomobject]@{ position = [int]$position; token = $property.Name }
          }
        }
        $abstractText = (($tokens | Sort-Object position | Select-Object -First 60 | ForEach-Object { $_.token }) -join " ")
        if ($abstractText) {
          $abstract = $abstractText
          if ($tokens.Count -gt 60) { $abstract += "..." }
        }
      }

      $papers += [ordered]@{
        title = $work.title
        display_name = $work.display_name
        year = $work.publication_year
        authors = $authorNames
        venue = $venueName
        citationCount = if ($null -ne $work.cited_by_count) { $work.cited_by_count } else { 0 }
        is_oa = $work.open_access.is_oa
        oa_url = $openAccessUrl
        doi = $doi
        topics = $topics
        abstract_preview = $abstract
        url = $work.id
      }
    }
  }

  $totalWorks = $Response.meta.count
  $topFields = $fieldCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3 | ForEach-Object { $_.Key }

  $avgCitations = 0
  if ($papers.Count -gt 0) {
    $avgCitations = [Math]::Round(($papers | ForEach-Object { $_.citationCount } | Measure-Object -Average).Average, 1)
  }

  $recentPapers = @($papers | Where-Object { $_.year -and $_.year -ge 2023 })
  $recentRatio = if ($papers.Count -gt 0) { [Math]::Round($recentPapers.Count / $papers.Count * 100, 0) } else { 0 }

  $fieldMaturity = "needs_literature_check"
  if ($totalWorks -gt 10000 -and $avgCitations -gt 30) {
    $fieldMaturity = "established_research_area"
  } elseif ($totalWorks -gt 1000 -or $recentRatio -gt 60) {
    $fieldMaturity = "active_research_area"
  } elseif ($totalWorks -gt 100) {
    $fieldMaturity = "emerging_research_area"
  }

  $highCitationPapers = @($papers | Where-Object { $_.citationCount -gt 50 } | Select-Object -First 3)

  $credibilityQuestions = @(
    "What peer-reviewed or preprint literature supports the central claim?",
    "Is the proposed method novel, or mainly an application of known methods?"
  )

  if ($highCitationPapers.Count -gt 0) {
    $credibilityQuestions += "Do the high-citation papers ($($highCitationPapers.Count) found) support or contradict the project's claims?"
  }

  if ($recentRatio -gt 70) {
    $credibilityQuestions += "This is a rapidly evolving field ($recentRatio% papers from 2023+). Are the project's methods current with the latest research?"
  }

  $scientificContext = "OpenAlex found $totalWorks works for '$Topic' (fallback from Semantic Scholar). "
  $scientificContext += "Top topics: $($topFields -join ', '). "
  $scientificContext += "Average citations: $avgCitations. "
  $scientificContext += "Recent activity: $recentRatio% papers from 2023+. "

  if ($fieldMaturity -eq "established_research_area") {
    $scientificContext += "This is an established research area with substantial prior work."
  } elseif ($fieldMaturity -eq "active_research_area") {
    $scientificContext += "This is an active research area with ongoing publications."
  } elseif ($fieldMaturity -eq "emerging_research_area") {
    $scientificContext += "This is an emerging research area with limited prior work."
  } else {
    $scientificContext += "Limited literature found. Manual literature review recommended."
  }

  [ordered]@{
    mode = "openalex_fallback"
    query = $Topic
    source = "OpenAlex API"
    fallback_reason = $FallbackReason
    total_works_found = $totalWorks
    works_returned = $papers.Count
    papers = $papers
    field_maturity = $fieldMaturity
    top_topics = $topFields
    average_citations = $avgCitations
    recent_paper_ratio = $recentRatio
    high_citation_papers_count = $highCitationPapers.Count
    scientific_context = $scientificContext
    credibility_questions = $credibilityQuestions
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
      description = "Search academic literature context. Tries Semantic Scholar first, falls back to OpenAlex if rate limited. Returns papers with citations, field maturity assessment, and credibility questions for verifying project claims."
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

You assist human reviewers for a DeSci funding round. You do NOT make final funding decisions. Your job is to reduce reviewer workload by producing structured, evidence-aware review support, especially by identifying what academic context still needs verification for the project's domain and claims.

Your workflow:
1. First, get the full project detail using get_project_detail.
2. Search for similar or related projects using search_projects to enable cross-project comparison.
3. Compare the target project with related projects using compare_projects.
4. Search academic context for the project's domain and key claims using search_academic_context.
5. Synthesize all gathered evidence into a final structured review.

You MUST call tools to gather information before producing your review. Do not guess or fabricate evidence.

Academic assessment is your core value-add. For each project, you must answer:
- Duplication check: Does similar academic research, prior work, or in-round work appear to exist?
- Novelty assessment: Is the project proposing something genuinely new, or reapplying known methods?
- Gap identification: Does the project address an actual gap in literature, tooling, practice, or reviewer evidence?

Academic context caution:
- The current search_academic_context tool uses Semantic Scholar API results first, with OpenAlex fallback if Semantic Scholar is rate limited or unavailable. It does not use AMiner yet.
- Semantic Scholar and OpenAlex results are real retrieved paper metadata, but they are not exhaustive and do not by themselves validate a project claim.
- If academic context is missing, sparse, or based on general model knowledge, label it as "needs verification" and do not present it as citation-backed evidence.
- Only describe a claim as contradicting academic consensus when a verified source/tool result supports that. Otherwise, phrase it as "potential conflict or concern to verify."

Guidelines:
- For funding_memory_observations: focus on DeSci alignment, whether the project type matches the funding round goals, and how it compares to other projects in this round. No funding amounts or scores are available in this dataset.
- For cross_project_comparison: compare progress, evidence level, and domain overlap. Identify if projects are redundant, complementary, or unrelated.
- For risk_flags: cite the exact project claim or missing artifact that triggers the risk. Flag aspirational claims that cannot be verified. Flag potential academic-consensus conflicts only as verification targets unless verified literature is available.
- For extracted_claims: separate verifiable claims (has artifact, demo, or evidence) from aspirational claims (future promises). Mark aspirational claims explicitly.
- For milestone_assessment: assess whether stated progress maps to concrete, inspectable artifacts. If no milestones exist, say so explicitly.

After gathering sufficient information, produce your final review as a JSON object with these fields:

Required fields:
- mode: string, must be "agent-glm-5.1"
- project_entity_id: string
- participation_id: string
- project_name: string
- executive_summary: string
- extracted_claims: string[]
- milestone_assessment: string[]
- evidence_found: string[]
- missing_evidence: string[]
- academic_context_queries_for_aminer: string[] (legacy field name; include Semantic Scholar / future AMiner queries)
- academic_context_results: string[]
- cross_project_comparison: string
- funding_memory_observations: string[]
- risk_flags: array of objects with risk, severity, and reason
- suggested_reviewer_questions: string[]
- human_review_support_status: one of ready_for_review, needs_more_evidence, high_risk_claims

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

  $retryCount = 0
  $response = $null

  while ($retryCount -le $MaxRetries) {
    try {
      $response = Invoke-RestMethod `
        -Uri "https://api.z.ai/api/paas/v4/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $body
      break
    } catch {
      $retryCount++
      if ($retryCount -le $MaxRetries) {
        $waitSec = $retryCount * 5
        Write-Host "  API call failed (retry $retryCount/$MaxRetries). Retrying in ${waitSec}s..." -ForegroundColor Yellow
        Start-Sleep -Seconds $waitSec
      } else {
        Write-Host "API call failed at turn $turn after $MaxRetries retries" -ForegroundColor Red
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
    }
  }

  if (-not $response) { break }

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
