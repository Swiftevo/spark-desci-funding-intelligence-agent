param(
  [string]$SparkProjectsPath = ".\data\projects.json",
  [string]$Gr23EntityPath = ".\outputs\gr23-integrity\gr23-entity-matching.local.json",
  [string]$OutDir = ".\outputs\gr23-integrity",
  [double]$StrongTitleThreshold = 0.82,
  [double]$PossibleTitleThreshold = 0.68
)

$ErrorActionPreference = "Stop"

function Assert-FileExists {
  param(
    [string]$Path,
    [string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "$Label file not found: $Path"
  }
}

function Normalize-Text {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  return (($Value.ToLowerInvariant() -replace "[^a-z0-9]+", " ").Trim() -replace "\s+", " ")
}

function Normalize-Domain {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $match = [regex]::Match($Value, "https?://([^/\s)]+)")
  if (-not $match.Success) {
    return ""
  }

  $domainHost = $match.Groups[1].Value.ToLowerInvariant()
  if ($domainHost.StartsWith("www.")) {
    $domainHost = $domainHost.Substring(4)
  }

  return $domainHost
}

function Get-GithubHandles {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return @()
  }

  $handles = [System.Collections.ArrayList]::new()
  foreach ($match in [regex]::Matches($Value, "github\.com/([^/\s?#)]+)")) {
    [void]$handles.Add($match.Groups[1].Value.Trim("@").ToLowerInvariant())
  }
  return @($handles | Select-Object -Unique)
}

function Get-SocialHandles {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return @()
  }

  $handles = [System.Collections.ArrayList]::new()
  foreach ($match in [regex]::Matches($Value, "(?:twitter\.com|x\.com)/([^/\s?#)]+)")) {
    [void]$handles.Add($match.Groups[1].Value.Trim("@").ToLowerInvariant())
  }
  return @($handles | Select-Object -Unique)
}

function Get-TokenSet {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return @()
  }

  return @(
    Normalize-Text $Text -split " " |
      Where-Object { $_.Length -ge 3 } |
      Select-Object -Unique
  )
}

function Get-Jaccard {
  param(
    [string[]]$A,
    [string[]]$B
  )

  $setA = @($A | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
  $setB = @($B | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

  if ($setA.Count -eq 0 -or $setB.Count -eq 0) {
    return 0
  }

  $intersection = @($setA | Where-Object { $setB -contains $_ })
  $union = @($setA + $setB | Select-Object -Unique)

  if ($union.Count -eq 0) {
    return 0
  }

  return [Math]::Round($intersection.Count / $union.Count, 4)
}

function Get-Overlap {
  param(
    [string[]]$A,
    [string[]]$B
  )

  return @(
    @($A | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) |
      Where-Object { $B -contains $_ } |
      Select-Object -Unique
  )
}

Assert-FileExists -Path $SparkProjectsPath -Label "Spark projects"
Assert-FileExists -Path $Gr23EntityPath -Label "GR23 entity matching data"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$sparkData = Get-Content -LiteralPath $SparkProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sparkProjects = if ($sparkData.projects -is [array]) { $sparkData.projects } else { @($sparkData.projects) }
$gr23Parsed = Get-Content -LiteralPath $Gr23EntityPath -Raw -Encoding UTF8 | ConvertFrom-Json
$gr23Projects = if ($gr23Parsed -is [array]) { $gr23Parsed } else { @($gr23Parsed) }

$sparkEntities = foreach ($project in $sparkProjects) {
  $textBlob = @(
    $project.project_name
    $project.link
    $project.raw_text
    $project.what_are_you_making
    $project.impact
    $project.progress
  ) -join "`n"

  [pscustomobject][ordered]@{
    project_entity_id = $project.project_entity_id
    project_name = $project.project_name
    normalized_title = Normalize-Text $project.project_name
    link = $project.link
    website_domain = Normalize-Domain $textBlob
    github_handles = @(Get-GithubHandles $textBlob)
    social_handles = @(Get-SocialHandles $textBlob)
    title_tokens = @(Get-TokenSet $project.project_name)
    text_tokens = @(Get-TokenSet $textBlob)
  }
}

$matches = [System.Collections.ArrayList]::new()

foreach ($gr23 in $gr23Projects) {
  $gr23Title = [string]$gr23.title
  $gr23TitleTokens = @(Get-TokenSet $gr23Title)
  $gr23GithubHandles = @(
    @($gr23.project_github, $gr23.user_github) |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Select-Object -Unique
  )
  $gr23SocialHandles = @(
    @($gr23.project_twitter) |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Select-Object -Unique
  )
  $gr23Domain = [string]$gr23.website_domain

  foreach ($spark in $sparkEntities) {
    $reasons = [System.Collections.ArrayList]::new()
    $confidence = "no_match"
    $score = 0.0

    $githubOverlap = @(Get-Overlap -A $gr23GithubHandles -B $spark.github_handles)
    $socialOverlap = @(Get-Overlap -A $gr23SocialHandles -B $spark.social_handles)
    $domainMatch = (
      -not [string]::IsNullOrWhiteSpace($gr23Domain) -and
      -not [string]::IsNullOrWhiteSpace($spark.website_domain) -and
      $gr23Domain -eq $spark.website_domain
    )
    $gr23NormalizedTitle = Normalize-Text $gr23Title
    $sparkNormalizedTitle = $spark.normalized_title
    $titleExactMatch = (
      -not [string]::IsNullOrWhiteSpace($gr23NormalizedTitle) -and
      -not [string]::IsNullOrWhiteSpace($sparkNormalizedTitle) -and
      $gr23NormalizedTitle -eq $sparkNormalizedTitle
    )
    $titleContainsMatch = (
      -not $titleExactMatch -and
      -not [string]::IsNullOrWhiteSpace($gr23NormalizedTitle) -and
      -not [string]::IsNullOrWhiteSpace($sparkNormalizedTitle) -and
      [Math]::Min($gr23NormalizedTitle.Length, $sparkNormalizedTitle.Length) -ge 5 -and
      (
        $gr23NormalizedTitle.Contains($sparkNormalizedTitle) -or
        $sparkNormalizedTitle.Contains($gr23NormalizedTitle)
      )
    )
    $titleScore = Get-Jaccard -A $gr23TitleTokens -B $spark.title_tokens
    $textScore = Get-Jaccard -A $gr23TitleTokens -B $spark.text_tokens

    if ($titleExactMatch) {
      [void]$reasons.Add("exact_title_match")
      $score += 1.0
    } elseif ($titleContainsMatch) {
      [void]$reasons.Add("title_contains_match")
      $score += 0.7
    }
    if ($githubOverlap.Count -gt 0) {
      [void]$reasons.Add("github_handle_overlap:$($githubOverlap -join ',')")
      $score += 1.0
    }
    if ($socialOverlap.Count -gt 0) {
      [void]$reasons.Add("social_handle_overlap:$($socialOverlap -join ',')")
      $score += 0.9
    }
    if ($domainMatch) {
      [void]$reasons.Add("website_domain_match:$gr23Domain")
      $score += 1.0
    }
    if ($titleScore -ge $StrongTitleThreshold) {
      [void]$reasons.Add("strong_title_similarity:$titleScore")
      $score += 0.85
    } elseif ($titleScore -ge $PossibleTitleThreshold) {
      [void]$reasons.Add("possible_title_similarity:$titleScore")
      $score += 0.55
    } elseif ($textScore -ge $PossibleTitleThreshold) {
      [void]$reasons.Add("title_terms_in_spark_text:$textScore")
      $score += 0.45
    }

    if ($score -ge 1.0) {
      $confidence = "confirmed_or_strong"
    } elseif ($score -ge 0.55) {
      $confidence = "possible"
    }

    if ($confidence -ne "no_match") {
      [void]$matches.Add([pscustomobject][ordered]@{
        confidence = $confidence
        score = [Math]::Round($score, 4)
        gr23_project_key = $gr23.project_key
        gr23_title = $gr23.title
        spark_project_entity_id = $spark.project_entity_id
        spark_project_name = $spark.project_name
        reasons = @($reasons)
        title_similarity = $titleScore
        text_similarity = $textScore
      })
    }
  }
}

$bestMatches = @(
  $matches |
    Sort-Object -Property gr23_project_key, score -Descending |
    Group-Object -Property gr23_project_key |
    ForEach-Object {
      $_.Group | Sort-Object -Property score -Descending | Select-Object -First 1
    } |
    Sort-Object -Property confidence, score -Descending
)

$summary = [ordered]@{
  generated_at = (Get-Date).ToString("s")
  note = "Entity matching uses local redacted GR23 matching keys and Spark 49-project metadata. Matches are signals for human review, not definitive identity resolution."
  spark_project_count = $sparkProjects.Count
  gr23_project_count = $gr23Projects.Count
  match_count = @($matches).Count
  best_match_count = @($bestMatches).Count
  confirmed_or_strong_count = @($bestMatches | Where-Object { $_.confidence -eq "confirmed_or_strong" }).Count
  possible_count = @($bestMatches | Where-Object { $_.confidence -eq "possible" }).Count
}

$report = [ordered]@{
  summary = $summary
  best_matches = @($bestMatches)
  all_matches = @($matches | Sort-Object -Property score -Descending)
}

$reportPath = Join-Path $OutDir "gr23-spark-overlap-report.json"
$csvPath = Join-Path $OutDir "gr23-spark-overlap-best-matches.csv"

$report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $reportPath -Encoding UTF8
$bestMatches | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "GR23 x Spark overlap matching complete." -ForegroundColor Cyan
Write-Host "Spark projects: $($sparkProjects.Count)"
Write-Host "GR23 projects:  $($gr23Projects.Count)"
Write-Host "All matches:    $(@($matches).Count)"
Write-Host "Best matches:   $(@($bestMatches).Count)"
Write-Host "Strong matches: $($summary.confirmed_or_strong_count)"
Write-Host "Possible:       $($summary.possible_count)"
Write-Host ""
Write-Host "Report: $reportPath"
Write-Host "CSV:    $csvPath"
Write-Host ""
Write-Host "These are entity-match signals for human review, not definitive overlap proof." -ForegroundColor Yellow
