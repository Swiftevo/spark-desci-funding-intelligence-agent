param(
  [string]$Query,
  [string]$Domain,
  [string]$CacheDir = ".\data\academic-cache",
  [int]$Limit = 3
)

$ErrorActionPreference = "Stop"

if (-not $Query -and -not $Domain) {
  Write-Error "Missing -Query or -Domain. Example: .\scripts\search-academic-cache.ps1 -Query 'LLM bias' -Domain 'AI / Data'"
}

$Query = if ($Query) { $Query.Trim().ToLower() } else { "" }
$Domain = if ($Domain) { $Domain.Trim().ToLower() } else { "" }

$domainMapping = @{
  "ai / data" = @("ai-llm-bias", "ai-decentralized")
  "biotech / health" = @("biotech-health-ai", "biotech-health-data")
  "education" = @("education-digital", "education-community")
  "governance / dao" = @("governance-dao", "governance-funding")
  "ocean / marine" = @("ocean-coral", "ocean-marine")
  "environment / climate" = @("environment-climate", "environment-solar")
  "space / physics" = @("space-physics", "space-lunar")
  "social / community" = @("social-community", "social-narrative")
  "art / culture" = @("art-culture", "art-preservation")
  "agriculture" = @("agriculture")
}

$searchDomains = @()
if ($Domain -and $domainMapping.ContainsKey($Domain)) {
  $searchDomains = $domainMapping[$Domain]
} elseif ($Domain) {
  $searchDomains = @($Domain -replace "[ /]", "-")
} else {
  $searchDomains = @($domainMapping.Values | ForEach-Object { $_ } | Select-Object -Unique)
}

$allPapers = @()
$totalPapersInCache = 0

if (Test-Path -LiteralPath $CacheDir) {
  $totalPapersInCache = @(Get-ChildItem -LiteralPath $CacheDir -Recurse -Filter "*.json").Count
}

foreach ($domainFolder in $searchDomains) {
  $folderPath = Join-Path $CacheDir $domainFolder
  
  if (-not (Test-Path -LiteralPath $folderPath)) {
    continue
  }
  
  $jsonFiles = Get-ChildItem -LiteralPath $folderPath -Filter "*.json"
  
  foreach ($file in $jsonFiles) {
    try {
      $paper = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
      
      $score = 0
      $titleLower = $paper.title.ToLower()
      $topicsLower = ($paper.topics -join " ").ToLower()
      
      if ($Query) {
        $queryTerms = $Query -split " " | Where-Object { $_.Length -gt 2 }
        
        foreach ($term in $queryTerms) {
          if ($titleLower.Contains($term)) { $score += 3 }
          if ($topicsLower.Contains($term)) { $score += 2 }
        }
      }
      
      if ($Domain) {
        $score += 1
      }
      
      if ($score -gt 0) {
        $allPapers += [ordered]@{
          score = $score
          openalex_id = $paper.openalex_id
          title = $paper.title
          domain_category = $paper.domain_category
          year = $paper.year
          authors = $paper.authors
          venue = $paper.venue
          cited_by_count = $paper.cited_by_count
          doi = $paper.doi
          is_oa = $paper.is_oa
          oa_url = $paper.oa_url
          topics = $paper.topics
          cached_at = $paper.cached_at
        }
      }
    } catch {
      continue
    }
  }
}

$matchedPapers = @($allPapers | Sort-Object { $_.score } -Descending | Select-Object -First $Limit)

$result = [ordered]@{
  mode = "local_cache"
  query = $Query
  domain = $Domain
  source = "Local Academic Cache"
  cache_dir = $CacheDir
  search_timestamp = (Get-Date).ToString("s")
  total_papers_in_cache = $totalPapersInCache
  matched_papers = $matchedPapers.Count
  papers = $matchedPapers
  field_maturity = if ($matchedPapers.Count -gt 0) { "has_cached_papers" } else { "no_cached_match" }
  scientific_context = if ($matchedPapers.Count -gt 0) {
    "Found $($matchedPapers.Count) cached papers matching query. These are pre-cached metadata, not exhaustive literature verification."
  } else {
    "No matching papers in local cache. This cache contains $totalPapersInCache paper metadata records. Full literature search requires API access."
  }
  credibility_questions = @(
    "What peer-reviewed or preprint literature supports the central claim?",
    "Is the proposed method novel, or mainly an application of known methods?"
  )
  cache_note = "Local cache contains paper metadata only. For full verification, access the open access PDF links or use Semantic Scholar / OpenAlex APIs directly."
}

$result | ConvertTo-Json -Depth 20
