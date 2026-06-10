param(
  [string]$Query,
  [string]$OutPath,
  [int]$Limit = 5
)

$ErrorActionPreference = "Stop"

if (-not $Query) {
  Write-Error "Missing -Query. Example: .\scripts\search-openalex.ps1 -Query 'LLM funding evaluation'"
}

$topic = $Query.Trim()
$encodedQuery = [System.Net.WebUtility]::UrlEncode($topic)
$selectFields = "id,title,display_name,publication_year,authorships,primary_location,doi,open_access,cited_by_count,topics"

$uri = "https://api.openalex.org/works?search=$encodedQuery&per_page=$Limit&select=$selectFields"

if ($env:OPENALEX_API_KEY) {
  $encodedApiKey = [Uri]::EscapeDataString($env:OPENALEX_API_KEY)
  $uri += "&api_key=$encodedApiKey"
}

Write-Host "Searching OpenAlex: $topic" -ForegroundColor Gray
Write-Host "URI: https://api.openalex.org/works?search=$encodedQuery&per_page=$Limit&select=$selectFields" -ForegroundColor DarkGray

try {
  $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30
} catch {
  $errorMsg = $_.Exception.Message
  Write-Error "OpenAlex API call failed: $errorMsg"
}

$papers = @()
$fieldCounts = @{}

if ($response.results -and $response.results.Count -gt 0) {
  foreach ($work in $response.results) {
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

    $papers += [ordered]@{
      openalex_id = $work.id
      title = $work.title
      display_name = $work.display_name
      year = $work.publication_year
      authors = $authorNames
      venue = $venueName
      cited_by_count = $work.cited_by_count
      is_oa = $work.open_access.is_oa
      oa_url = $openAccessUrl
      doi = $doi
      topics = $topics
      abstract_preview = $null
      url = $work.id
    }
  }
}

$totalWorks = $response.meta.count
$topFields = @($fieldCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3 | ForEach-Object { $_.Key })

$avgCitations = 0
if ($papers.Count -gt 0) {
  $avgCitations = [Math]::Round(($papers | ForEach-Object { $_.cited_by_count } | Measure-Object -Average).Average, 1)
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

$highCitationPapers = @($papers | Where-Object { $_.cited_by_count -gt 50 } | Select-Object -First 3)

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

$scientificContext = "OpenAlex found $totalWorks works for '$topic'. "
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

$context = [ordered]@{
  mode = "openalex"
  query = $topic
  source = "OpenAlex API"
  api_version = "works"
  search_timestamp = (Get-Date).ToString("s")
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

$json = $context | ConvertTo-Json -Depth 20

if ($OutPath) {
  $json | Set-Content -LiteralPath $OutPath -Encoding UTF8
  Write-Host "OpenAlex context written to $OutPath" -ForegroundColor Green
}

$json
