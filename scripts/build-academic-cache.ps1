param(
  [string]$OutputDir = ".\data\academic-cache"
)

$ErrorActionPreference = "Stop"

$domains = @(
  @{ name = "ai-llm-bias"; query = "LLM bias fairness evaluation" },
  @{ name = "ai-decentralized"; query = "decentralized AI systems" },
  @{ name = "biotech-health-ai"; query = "AI healthcare diagnosis" },
  @{ name = "biotech-health-data"; query = "health data privacy" },
  @{ name = "education-digital"; query = "digital learning platforms" },
  @{ name = "education-community"; query = "community based education" },
  @{ name = "governance-dao"; query = "DAO governance mechanisms" },
  @{ name = "governance-funding"; query = "public goods funding mechanisms" },
  @{ name = "ocean-coral"; query = "coral reef restoration" },
  @{ name = "ocean-marine"; query = "marine conservation technology" },
  @{ name = "environment-climate"; query = "regenerative agriculture" },
  @{ name = "environment-solar"; query = "solar grid systems" },
  @{ name = "space-physics"; query = "low cost space access" },
  @{ name = "space-lunar"; query = "lunar exploration technology" },
  @{ name = "social-community"; query = "community governance participation" },
  @{ name = "social-narrative"; query = "narrative analysis methods" },
  @{ name = "art-culture"; query = "art technology digital" },
  @{ name = "art-preservation"; query = "cultural heritage preservation" },
  @{ name = "agriculture"; query = "regenerative farming systems" },
  @{ name = "desci-general"; query = "decentralized science DeSci" }
)

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$totalCached = 0
$totalOA = 0

foreach ($domain in $domains) {
  $domainName = $domain.name
  $query = $domain.query
  
  Write-Host "Processing: $domainName" -ForegroundColor Cyan
  
  $encodedQuery = [System.Net.WebUtility]::UrlEncode($query)
  $selectFields = "id,title,display_name,publication_year,authorships,primary_location,doi,open_access,cited_by_count,topics"
  $uri = "https://api.openalex.org/works?search=$encodedQuery&per_page=2&select=$selectFields"
  
  try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30
    
    $domainDir = Join-Path $OutputDir $domainName
    New-Item -ItemType Directory -Force -Path $domainDir | Out-Null
    
    $paperIndex = 0
    foreach ($work in $response.results) {
      $paperIndex++
      
      $authorNames = @()
      if ($work.authorships) {
        $authorNames = @($work.authorships | ForEach-Object { $_.author.display_name } | Where-Object { $_ } | Select-Object -First 5)
      }
      
      $venueName = $null
      if ($work.primary_location -and $work.primary_location.source) {
        $venueName = $work.primary_location.source.display_name
      }
      
      $topics = @()
      if ($work.topics) {
        $topics = @($work.topics | ForEach-Object { $_.display_name } | Where-Object { $_ } | Select-Object -First 3)
      }
      
      $paperData = [ordered]@{
        openalex_id = $work.id
        title = $work.title
        domain_category = $domainName
        year = $work.publication_year
        authors = $authorNames
        venue = $venueName
        cited_by_count = $work.cited_by_count
        doi = $work.doi
        is_oa = $work.open_access.is_oa
        oa_url = $work.open_access.oa_url
        topics = $topics
        cached_at = (Get-Date).ToString("s")
      }
      
      $paperFile = Join-Path $domainDir "paper-$paperIndex.json"
      $paperData | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $paperFile -Encoding UTF8
      
      $totalCached++
      if ($work.open_access.is_oa) { $totalOA++ }
      
      Write-Host "  Cached: $($work.title) (OA: $($work.open_access.is_oa))" -ForegroundColor Gray
    }
    
    Start-Sleep -Milliseconds 500
    
  } catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "=== Cache Build Complete ===" -ForegroundColor Green
Write-Host "Total papers cached: $totalCached"
Write-Host "Open Access papers: $totalOA"
Write-Host "Cache directory: $OutputDir"