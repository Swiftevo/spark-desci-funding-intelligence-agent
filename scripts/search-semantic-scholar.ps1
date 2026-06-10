param(
  [string]$Query,
  [string]$OutPath,
  [int]$Limit = 5
)

$ErrorActionPreference = "Stop"

if (-not $Query) {
  Write-Error "Missing -Query. Example: .\scripts\search-semantic-scholar.ps1 -Query 'LLM funding evaluation'"
}

$topic = $Query.Trim()
$encodedQuery = [Uri]::EscapeDataString($topic)

$fields = "title,abstract,authors,year,citationCount,influentialCitationCount,fieldsOfStudy,publicationVenue,openAccessPdf,externalIds,url"

$uri = "https://api.semanticscholar.org/graph/v1/paper/search?query=$encodedQuery&fields=$fields&limit=$Limit"

Write-Host "Searching Semantic Scholar: $topic" -ForegroundColor Gray

$headers = @{}
if ($env:SEMANTIC_SCHOLAR_API_KEY) {
  $headers["x-api-key"] = $env:SEMANTIC_SCHOLAR_API_KEY
}

try {
  $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -TimeoutSec 30
} catch {
  $errorMsg = $_.Exception.Message
  if ($errorMsg -match "429") {
    Write-Warning "Semantic Scholar rate limit hit. Wait and retry, or set SEMANTIC_SCHOLAR_API_KEY if you have one."
  }
  Write-Error "Semantic Scholar API call failed: $errorMsg"
}

$papers = @()
$fieldCounts = @{}

if ($response.data -and $response.data.Count -gt 0) {
  foreach ($paper in $response.data) {
    $fieldsOfStudy = @()
    if ($paper.fieldsOfStudy) {
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
    }

    $authorNames = @()
    if ($paper.authors) {
      $authorNames = @($paper.authors | ForEach-Object { $_.name } | Where-Object { $_ })
    }

    $pdfUrl = $null
    if ($paper.openAccessPdf -and $paper.openAccessPdf.url) {
      $pdfUrl = $paper.openAccessPdf.url
    }

    $doi = $null
    $arxivId = $null
    if ($paper.externalIds) {
      if ($paper.externalIds.DOI) { $doi = $paper.externalIds.DOI }
      if ($paper.externalIds.ArXiv) { $arxivId = $paper.externalIds.ArXiv }
    }

    $venueName = $null
    if ($paper.publicationVenue -and $paper.publicationVenue.name) {
      $venueName = $paper.publicationVenue.name
    } elseif ($paper.venue) {
      $venueName = $paper.venue
    }

    $abstractPreview = $null
    if ($paper.abstract) {
      $abstractPreview = $paper.abstract.Substring(0, [Math]::Min(300, $paper.abstract.Length))
      if ($paper.abstract.Length -gt 300) {
        $abstractPreview += "..."
      }
    }

    $papers += [ordered]@{
      paperId = $paper.paperId
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
      arxivId = $arxivId
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
$recentHighImpact = @($papers | Where-Object { $_.year -and $_.year -ge 2022 -and $_.influentialCitationCount -gt 10 } | Select-Object -First 3)

$credibilityQuestions = @(
  "What peer-reviewed or preprint literature supports the central claim?",
  "Is the proposed method novel, or mainly an application of known methods?"
)

if ($topFields -contains "Computer Science") {
  $credibilityQuestions += "Are there known benchmark datasets, evaluation protocols, or reproducibility baselines for this task?"
}

if ($highCitationPapers.Count -gt 0) {
  $credibilityQuestions += "Do the high-citation papers ($($highCitationPapers.Count) found) support or contradict the project's claims?"
}

if ($recentRatio -gt 70) {
  $credibilityQuestions += "This is a rapidly evolving field ($recentRatio% papers from 2023+). Are the project's methods current with the latest research?"
}

$scientificContext = "Semantic Scholar found $totalPapers papers for '$topic'. "
$scientificContext += "Top fields: $($topFields -join ', '). "
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
  mode = "semantic_scholar"
  query = $topic
  source = "Semantic Scholar API"
  api_version = "graph/v1"
  search_timestamp = (Get-Date).ToString("s")
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

$json = $context | ConvertTo-Json -Depth 20

if ($OutPath) {
  $json | Set-Content -LiteralPath $OutPath -Encoding UTF8
  Write-Host "Semantic Scholar context written to $OutPath" -ForegroundColor Green
}

$json
