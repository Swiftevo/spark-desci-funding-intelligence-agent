param(
  [string]$Url,
  [string]$OutPath
)

$ErrorActionPreference = "Stop"

if (-not $Url) {
  Write-Error "Missing -Url. Example: .\scripts\fetch-web-resource.ps1 -Url 'https://github.com/user/repo'"
}

$Url = $Url.Trim()

Write-Host "Fetching: $Url" -ForegroundColor Gray

$result = [ordered]@{
  url = $Url
  fetch_timestamp = (Get-Date).ToString("s")
  status = "unknown"
  resource_type = "unknown"
  content_preview = $null
  key_findings = @()
  error = $null
}

$parsedUri = $null
if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$parsedUri) -or ($parsedUri.Scheme -notin @("http", "https"))) {
  $result.status = "error"
  $result.error = "Unsupported or invalid URL. Only absolute http/https URLs are allowed."
  $json = $result | ConvertTo-Json -Depth 20
  if ($OutPath) {
    $json | Set-Content -LiteralPath $OutPath -Encoding UTF8
    Write-Host "Web resource info written to $OutPath" -ForegroundColor Green
  }
  $json
  exit 0
}

$isGitHub = $Url -match "github\.com"
$isArtizen = $Url -match "artizen\.fund"

if ($isGitHub) {
  $result.resource_type = "github"
  
  $apiUrl = $Url -replace "github\.com", "api.github.com/repos"
  if ($apiUrl -match "api\.github\.com/repos/([^/]+/[^/]+)") {
    $repoPath = $Matches[1]
    $apiUrl = "https://api.github.com/repos/$repoPath"
    
    try {
      $headers = @{
        "User-Agent" = "Spark-DeSci-Agent/1.0"
        "Accept" = "application/vnd.github.v3+json"
      }
      
      if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "token $env:GITHUB_TOKEN"
      }
      
      $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers -TimeoutSec 30
      $rootFileCount = $null
      $rootDirCount = $null
      $hasReadme = $false
      $codePresenceSignals = @()
      $contentsError = $null

      try {
        $rootItemsResponse = Invoke-RestMethod -Uri "$apiUrl/contents" -Method Get -Headers $headers -TimeoutSec 30
        $rootItems = @($rootItemsResponse | ForEach-Object { $_ })
        $rootNames = @($rootItems | ForEach-Object { $_.name } | Where-Object { $_ })
        $rootFileCount = @($rootItems | Where-Object { $_.PSObject.Properties["type"].Value -eq "file" }).Count
        $rootDirCount = @($rootItems | Where-Object { $_.PSObject.Properties["type"].Value -eq "dir" }).Count
        $hasReadme = @($rootNames | Where-Object { $_ -match "^README(\.|$)" }).Count -gt 0

        $codeLikeFiles = @("package.json", "pyproject.toml", "requirements.txt", "Cargo.toml", "go.mod", "pom.xml", "setup.py", "Makefile", "Dockerfile")
        foreach ($name in $codeLikeFiles) {
          if ($rootNames -contains $name) { $codePresenceSignals += $name }
        }

        $sourceDirs = @("src", "app", "lib", "contracts", "packages")
        foreach ($name in $sourceDirs) {
          if ($rootNames -contains $name) { $codePresenceSignals += "$name/" }
        }
      } catch {
        $contentsError = $_.Exception.Message
      }
      
      $result.status = "success"
      $result.content_preview = [ordered]@{
        name = $response.name
        full_name = $response.full_name
        description = $response.description
        stars = $response.stargazers_count
        forks = $response.forks_count
        open_issues = $response.open_issues_count
        language = $response.language
        created_at = $response.created_at
        pushed_at = $response.pushed_at
        license = $response.license.spdx_id
        topics = $response.topics
        homepage = $response.homepage
        root_file_count = $rootFileCount
        root_dir_count = $rootDirCount
        has_readme = $hasReadme
        code_presence_signals = $codePresenceSignals
      }
      
      $result.key_findings = @()
      
      if ($response.stargazers_count -gt 100) {
        $result.key_findings += "Repository has $($response.stargazers_count) stars - indicates community interest"
      }
      
      if ($response.forks_count -gt 10) {
        $result.key_findings += "Repository has $($response.forks_count) forks - active development"
      }
      
      if ($response.pushed_at) {
        $lastPush = [DateTime]::Parse($response.pushed_at)
        $timeSpan = (Get-Date) - $lastPush
        $daysSincePush = [Math]::Floor($timeSpan.TotalDays)
        if ($daysSincePush -lt 30) {
          $result.key_findings += "Active development - last push $daysSincePush days ago"
        } elseif ($daysSincePush -lt 365) {
          $result.key_findings += "Recent activity - last push $daysSincePush days ago"
        } else {
          $result.key_findings += "Inactive - last push over a year ago ($daysSincePush days)"
        }
      }
      
      if (-not $response.description) {
        $result.key_findings += "No description provided - unclear project purpose"
      }
      
      if ($response.license) {
        $result.key_findings += "License: $($response.license.spdx_id)"
      } else {
        $result.key_findings += "No license specified"
      }
      
      if ($response.topics -and $response.topics.Count -gt 0) {
        $result.key_findings += "Topics: $($response.topics -join ', ')"
      }

      if ($null -ne $rootFileCount) {
        if ($hasReadme) {
          $result.key_findings += "README found in repository root"
        } else {
          $result.key_findings += "No README found in repository root"
        }

        if ($codePresenceSignals.Count -gt 0) {
          $result.key_findings += "Code/package signals found: $($codePresenceSignals -join ', ')"
        } else {
          $result.key_findings += "Root contents fetched, but no common code/package signals found"
        }
      } elseif ($contentsError) {
        $result.key_findings += "Could not inspect repository root contents"
      }
      
    } catch {
      $result.status = "error"
      $result.error = "GitHub API error: $($_.Exception.Message)"
    }
  }
} elseif ($isArtizen) {
  $result.resource_type = "artizen_project_page"
  
  try {
    $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 30 -UseBasicParsing
    $content = $response.Content
    
    $result.status = "success"
    
    $titleMatch = [regex]::Match($content, '<title[^>]*>([^<]+)</title>')
    if ($titleMatch.Success) {
      $result.content_preview = [ordered]@{
        title = $titleMatch.Groups[1].Value.Trim()
        content_length = $content.Length
      }
    }
    
    $result.key_findings = @("Artizen project page accessible")
    
    $githubPattern = "github\.com/[a-zA-Z0-9_\-/]+"
    if ($content -match $githubPattern) {
      $githubLinks = [regex]::Matches($content, $githubPattern) | ForEach-Object { $_.Value } | Select-Object -Unique
      if ($githubLinks) {
        $result.key_findings += "GitHub links found: $($githubLinks -join ', ')"
      }
    }
    
  } catch {
    $result.status = "error"
    $result.error = "Web fetch error: $($_.Exception.Message)"
  }
} else {
  $result.resource_type = "general_website"
  
  try {
    $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 30 -UseBasicParsing
    $content = $response.Content
    
    $result.status = "success"
    $result.content_preview = [ordered]@{
      content_length = $content.Length
      status_code = $response.StatusCode
    }
    
    $result.key_findings = @("Website accessible")
    
    $titleMatch = [regex]::Match($content, '<title[^>]*>([^<]+)</title>')
    if ($titleMatch.Success) {
      $result.key_findings += "Page title: $($titleMatch.Groups[1].Value.Trim())"
    }
    
  } catch {
    $result.status = "error"
    $result.error = "Web fetch error: $($_.Exception.Message)"
  }
}

$json = $result | ConvertTo-Json -Depth 20

if ($OutPath) {
  $json | Set-Content -LiteralPath $OutPath -Encoding UTF8
  Write-Host "Web resource info written to $OutPath" -ForegroundColor Green
}

$json
