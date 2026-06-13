param(
  [string]$RedactedDataPath = ".\outputs\gr23-integrity\gr23-redacted-data.json",
  [string]$OutDir = ".\outputs\gr23-integrity",
  [int]$SharedDonorProjectThreshold = 5,
  [double]$FailedThresholdRateWarning = 0.30,
  [double]$RepeatedAmountToleranceUsd = 0.01
)

$ErrorActionPreference = "Stop"

function Assert-FileExists {
  param(
    [string]$Path,
    [string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "$Label file not found: $Path. Run .\scripts\import-gr23-data.ps1 first."
  }
}

function Sum-Property {
  param(
    [object[]]$Rows,
    [string]$Property
  )

  if (-not $Rows -or $Rows.Count -eq 0) {
    return 0
  }

  $sum = ($Rows | Measure-Object -Property $Property -Sum).Sum
  if ($null -eq $sum) {
    return 0
  }

  return [double]$sum
}

function Average-Property {
  param(
    [object[]]$Rows,
    [string]$Property
  )

  if (-not $Rows -or $Rows.Count -eq 0) {
    return 0
  }

  $avg = ($Rows | Measure-Object -Property $Property -Average).Average
  if ($null -eq $avg) {
    return 0
  }

  return [double]$avg
}

function New-RiskFlag {
  param(
    [string]$Type,
    [string]$Severity,
    [string]$Reason,
    [object]$Evidence
  )

  return [pscustomobject][ordered]@{
    type = $Type
    severity = $Severity
    reason = $Reason
    evidence = $Evidence
  }
}

function Convert-ToAmountBucket {
  param([double]$AmountUsd)

  if ($AmountUsd -le 0) {
    return "0"
  }

  $rounded = [Math]::Round($AmountUsd / $RepeatedAmountToleranceUsd) * $RepeatedAmountToleranceUsd
  return $rounded.ToString("0.00", [System.Globalization.CultureInfo]::InvariantCulture)
}

Assert-FileExists -Path $RedactedDataPath -Label "Redacted GR23 data"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$data = Get-Content -LiteralPath $RedactedDataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$projects = @($data.projects)
$donations = @($data.donations)

$projectByKey = @{}
$payoutWalletToProject = @{}
foreach ($project in $projects) {
  $projectByKey[$project.project_key] = $project
  if (-not [string]::IsNullOrWhiteSpace($project.payout_wallet)) {
    $payoutWalletToProject[$project.payout_wallet] = $project
  }
}

$donationByProject = $donations | Group-Object -Property project_key
$donationByDonor = $donations | Group-Object -Property donor_wallet

$directSelfDonations = @(
  $donations | Where-Object {
    (-not [string]::IsNullOrWhiteSpace($_.donor_wallet)) -and
    (
      $_.donor_wallet -eq $_.grant_wallet -or
      (
        $projectByKey.ContainsKey($_.project_key) -and
        $_.donor_wallet -eq $projectByKey[$_.project_key].payout_wallet
      )
    )
  }
)

$projectWalletCrossDonations = @(
  $donations | Where-Object {
    (-not [string]::IsNullOrWhiteSpace($_.donor_wallet)) -and
    $payoutWalletToProject.ContainsKey($_.donor_wallet) -and
    $payoutWalletToProject[$_.donor_wallet].project_key -ne $_.project_key
  } | ForEach-Object {
    $sourceProject = $payoutWalletToProject[$_.donor_wallet]
    $targetProject = if ($projectByKey.ContainsKey($_.project_key)) { $projectByKey[$_.project_key] } else { $null }

    [pscustomobject][ordered]@{
      tx = $_.tx
      source_project_key = $sourceProject.project_key
      source_title = $sourceProject.title
      target_project_key = $_.project_key
      target_title = if ($targetProject) { $targetProject.title } else { "" }
      donor_wallet = $_.donor_wallet
      amount_usd = $_.amount_usd
      passport_success = $_.passport_success
      raw_score = $_.raw_score
    }
  }
)

$sharedDonors = @(
  foreach ($group in $donationByDonor) {
    if ([string]::IsNullOrWhiteSpace($group.Name)) {
      continue
    }

    $rows = @($group.Group)
    $projectKeys = @($rows | Select-Object -ExpandProperty project_key -Unique)
    if ($projectKeys.Count -lt $SharedDonorProjectThreshold) {
      continue
    }

    $failedRows = @($rows | Where-Object { $_.passport_success -eq $false })
    $successRows = @($rows | Where-Object { $_.passport_success -eq $true })

    [pscustomobject][ordered]@{
      donor_wallet = $group.Name
      project_count = $projectKeys.Count
      donation_count = $rows.Count
      total_amount_usd = [Math]::Round((Sum-Property -Rows $rows -Property "amount_usd"), 6)
      average_amount_usd = [Math]::Round((Average-Property -Rows $rows -Property "amount_usd"), 6)
      passport_success_count = $successRows.Count
      failed_threshold_count = $failedRows.Count
      average_raw_score = [Math]::Round((Average-Property -Rows $rows -Property "raw_score"), 6)
      project_keys = @($projectKeys)
    }
  }
)

$repeatedAmountPatterns = @(
  foreach ($group in $donationByDonor) {
    if ([string]::IsNullOrWhiteSpace($group.Name)) {
      continue
    }

    $rows = @($group.Group)
    $amountGroups = $rows |
      Where-Object { $_.amount_usd -gt 0 } |
      Group-Object -Property { Convert-ToAmountBucket -AmountUsd ([double]$_.amount_usd) }

    foreach ($amountGroup in $amountGroups) {
      $amountRows = @($amountGroup.Group)
      $projectKeys = @($amountRows | Select-Object -ExpandProperty project_key -Unique)

      if ($projectKeys.Count -lt 3) {
        continue
      }

      [pscustomobject][ordered]@{
        donor_wallet = $group.Name
        amount_bucket_usd = $amountGroup.Name
        project_count = $projectKeys.Count
        donation_count = $amountRows.Count
        project_keys = @($projectKeys)
      }
    }
  }
)

$projectReports = @(
  foreach ($project in $projects) {
    $rows = @($donations | Where-Object { $_.project_key -eq $project.project_key })
    $uniqueDonors = @($rows | Select-Object -ExpandProperty donor_wallet -Unique)
    $failedRows = @($rows | Where-Object { $_.passport_success -eq $false })
    $directRows = @($directSelfDonations | Where-Object { $_.project_key -eq $project.project_key })
    $incomingFromProjectWallets = @($projectWalletCrossDonations | Where-Object { $_.target_project_key -eq $project.project_key })
    $sharedDonorHits = @(
      $sharedDonors | Where-Object {
        $_.project_keys -contains $project.project_key
      }
    )
    $repeatedAmountHits = @(
      $repeatedAmountPatterns | Where-Object {
        $_.project_keys -contains $project.project_key
      }
    )

    $riskFlags = @()

    if ($directRows.Count -gt 0) {
      $riskFlags += New-RiskFlag `
        -Type "direct_self_donation" `
        -Severity "high" `
        -Reason "A donor wallet matches the project grant wallet or payout wallet. This is a deterministic wallet-match signal and requires operator verification." `
        -Evidence ([ordered]@{
          donation_count = $directRows.Count
          total_amount_usd = [Math]::Round((Sum-Property -Rows $directRows -Property "amount_usd"), 6)
        })
    }

    if ($incomingFromProjectWallets.Count -gt 0) {
      $riskFlags += New-RiskFlag `
        -Type "project_wallet_cross_donation" `
        -Severity "medium" `
        -Reason "A known payout wallet from another project donated to this project. This may be legitimate ecosystem support or may require reciprocal-support review." `
        -Evidence ([ordered]@{
          donation_count = $incomingFromProjectWallets.Count
          source_project_count = @($incomingFromProjectWallets | Select-Object -ExpandProperty source_project_key -Unique).Count
          total_amount_usd = [Math]::Round((Sum-Property -Rows $incomingFromProjectWallets -Property "amount_usd"), 6)
        })
    }

    $failedRate = if ($rows.Count -gt 0) { $failedRows.Count / $rows.Count } else { 0 }
    if ($rows.Count -gt 0 -and $failedRate -ge $FailedThresholdRateWarning) {
      $riskFlags += New-RiskFlag `
        -Type "failed_threshold_concentration" `
        -Severity "medium" `
        -Reason "A meaningful share of donations failed the passport / threshold check. This is not proof of misconduct, but should be reviewed." `
        -Evidence ([ordered]@{
          donation_count = $rows.Count
          failed_threshold_count = $failedRows.Count
          failed_threshold_rate = [Math]::Round($failedRate, 4)
        })
    }

    if ($sharedDonorHits.Count -gt 0) {
      $riskFlags += New-RiskFlag `
        -Type "shared_donor_cluster" `
        -Severity "medium" `
        -Reason "The project received donations from wallets that also supported many other projects in the same round." `
        -Evidence ([ordered]@{
          shared_donor_count = $sharedDonorHits.Count
          max_projects_touched_by_one_donor = (($sharedDonorHits | Measure-Object -Property project_count -Maximum).Maximum)
        })
    }

    if ($repeatedAmountHits.Count -gt 0) {
      $riskFlags += New-RiskFlag `
        -Type "repeated_amount_pattern" `
        -Severity "low" `
        -Reason "A donor used the same small amount bucket across at least three projects. This can be benign, but is useful for graph review." `
        -Evidence ([ordered]@{
          pattern_count = $repeatedAmountHits.Count
          amount_buckets = @($repeatedAmountHits | Select-Object -ExpandProperty amount_bucket_usd -Unique)
        })
    }

    $riskScore = 0
    foreach ($flag in $riskFlags) {
      switch ($flag.severity) {
        "high" { $riskScore += 3 }
        "medium" { $riskScore += 2 }
        default { $riskScore += 1 }
      }
    }

    [pscustomobject][ordered]@{
      project_key = $project.project_key
      title = $project.title
      donation_count = $rows.Count
      unique_donor_count = $uniqueDonors.Count
      total_amount_usd = [Math]::Round((Sum-Property -Rows $rows -Property "amount_usd"), 6)
      failed_threshold_count = $failedRows.Count
      failed_threshold_rate = [Math]::Round($failedRate, 4)
      direct_self_donation_count = $directRows.Count
      project_wallet_cross_donation_count = $incomingFromProjectWallets.Count
      shared_donor_cluster_count = $sharedDonorHits.Count
      repeated_amount_pattern_count = $repeatedAmountHits.Count
      risk_score = $riskScore
      risk_flags = @($riskFlags)
    }
  }
)

$graphEdges = @(
  $donations | ForEach-Object {
    [pscustomobject][ordered]@{
      source = $_.donor_wallet
      target = $_.project_key
      tx = $_.tx
      amount_usd = $_.amount_usd
      passport_success = $_.passport_success
      raw_score = $_.raw_score
      threshold = $_.threshold
      timestamp = $_.last_score_timestamp
    }
  }
)

$roundRiskSummary = [ordered]@{
  analyzed_at = (Get-Date).ToString("s")
  privacy_mode = "redacted_wallet_and_tx_ids"
  project_count = $projects.Count
  donation_count = $donations.Count
  unique_donor_count = @($donationByDonor | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) }).Count
  direct_self_donation_count = $directSelfDonations.Count
  project_wallet_cross_donation_count = $projectWalletCrossDonations.Count
  shared_donor_cluster_count = $sharedDonors.Count
  repeated_amount_pattern_count = $repeatedAmountPatterns.Count
  failed_threshold_count = @($donations | Where-Object { $_.passport_success -eq $false }).Count
  failed_threshold_rate = if ($donations.Count -gt 0) {
    [Math]::Round((@($donations | Where-Object { $_.passport_success -eq $false }).Count / $donations.Count), 4)
  } else {
    0
  }
  projects_requiring_manual_review = @(
    $projectReports |
      Where-Object { $_.risk_flags.Count -gt 0 } |
      Sort-Object -Property risk_score, failed_threshold_rate, donation_count -Descending |
      Select-Object -First 10
  )
}

$report = [ordered]@{
  round = "Gitcoin GR23 DeSci Community Round"
  note = "Risk signals are deterministic redacted-data checks for human review. They are not accusations or proof of misconduct."
  parameters = [ordered]@{
    shared_donor_project_threshold = $SharedDonorProjectThreshold
    failed_threshold_rate_warning = $FailedThresholdRateWarning
    repeated_amount_tolerance_usd = $RepeatedAmountToleranceUsd
  }
  round_risk_summary = $roundRiskSummary
  direct_self_donations = @($directSelfDonations)
  project_wallet_cross_donations = @($projectWalletCrossDonations)
  shared_donor_clusters = @($sharedDonors | Sort-Object -Property project_count, donation_count -Descending)
  repeated_amount_patterns = @($repeatedAmountPatterns | Sort-Object -Property project_count, donation_count -Descending)
  project_reports = @($projectReports | Sort-Object -Property risk_score, failed_threshold_rate, donation_count -Descending)
}

$reportPath = Join-Path $OutDir "gr23-integrity-report.json"
$projectReportPath = Join-Path $OutDir "gr23-project-risk-summary.json"
$graphJsonPath = Join-Path $OutDir "gr23-donor-project-graph.json"
$graphCsvPath = Join-Path $OutDir "gr23-donor-project-edges.csv"

$report | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $reportPath -Encoding UTF8
@($projectReports | Sort-Object -Property risk_score, failed_threshold_rate, donation_count -Descending) |
  ConvertTo-Json -Depth 20 |
  Set-Content -LiteralPath $projectReportPath -Encoding UTF8
[ordered]@{
  nodes = [ordered]@{
    donors = @($donationByDonor | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) } | ForEach-Object { $_.Name })
    projects = @($projects | Select-Object -ExpandProperty project_key)
  }
  edges = @($graphEdges)
} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $graphJsonPath -Encoding UTF8
$graphEdges | Export-Csv -LiteralPath $graphCsvPath -NoTypeInformation -Encoding UTF8

Write-Host "GR23 deterministic integrity analysis complete." -ForegroundColor Cyan
Write-Host "Projects analyzed: $($projects.Count)"
Write-Host "Donations analyzed: $($donations.Count)"
Write-Host "Direct self-donation signals: $($directSelfDonations.Count)"
Write-Host "Project wallet cross-donation signals: $($projectWalletCrossDonations.Count)"
Write-Host "Shared donor clusters: $($sharedDonors.Count)"
Write-Host "Repeated amount patterns: $($repeatedAmountPatterns.Count)"
Write-Host "Failed threshold rate: $($roundRiskSummary.failed_threshold_rate)"
Write-Host ""
Write-Host "Report:       $reportPath"
Write-Host "Project risk: $projectReportPath"
Write-Host "Graph JSON:   $graphJsonPath"
Write-Host "Graph CSV:    $graphCsvPath"
Write-Host ""
Write-Host "These are review-worthy signals only, not accusations." -ForegroundColor Yellow
