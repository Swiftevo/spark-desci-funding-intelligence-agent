param(
  [string]$ProjectInfoPath = "$HOME\Desktop\gitcoin grant 23 desci community round project information.txt",
  [string]$DonationPath = "$HOME\Desktop\gitcoin grant 23 desci community round small donation.txt",
  [string]$OutDir = ".\outputs\gr23-integrity",
  [string]$Salt = $env:GR23_REDACTION_SALT
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

function Get-FieldValue {
  param(
    [object]$Row,
    [string[]]$Names
  )

  foreach ($name in $Names) {
    if ($Row.PSObject.Properties.Name -contains $name) {
      return [string]$Row.$name
    }
  }

  return ""
}

function Normalize-Address {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $match = [regex]::Match($Value, "0x[a-fA-F0-9]{40}")
  if ($match.Success) {
    return $match.Value.ToLowerInvariant()
  }

  return ""
}

function Normalize-Hash {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $match = [regex]::Match($Value, "0x[a-fA-F0-9]{64}")
  if ($match.Success) {
    return $match.Value.ToLowerInvariant()
  }

  return ""
}

function Convert-ToDecimal {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return 0
  }

  $parsed = 0.0
  if ([double]::TryParse(
      $Value,
      [System.Globalization.NumberStyles]::Float,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [ref]$parsed
    )) {
    return $parsed
  }

  return 0
}

function Convert-ToBoolOrNull {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }

  $normalized = $Value.Trim().ToLowerInvariant()
  if ($normalized -in @("true", "1", "yes")) {
    return $true
  }
  if ($normalized -in @("false", "0", "no")) {
    return $false
  }

  return $null
}

function New-RedactedId {
  param(
    [string]$Prefix,
    [string]$Value,
    [string]$Salt
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$Salt|$($Value.ToLowerInvariant())")
    $hashBytes = $sha.ComputeHash($bytes)
    $hash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    return "$Prefix$($hash.Substring(0, 12))"
  } finally {
    $sha.Dispose()
  }
}

function Add-MapEntry {
  param(
    [hashtable]$Map,
    [string]$Kind,
    [string]$RawValue,
    [string]$RedactedValue
  )

  if ([string]::IsNullOrWhiteSpace($RawValue)) {
    return
  }

  if (-not $Map.ContainsKey($RawValue)) {
    $Map[$RawValue] = [ordered]@{
      kind = $Kind
      redacted = $RedactedValue
    }
  }
}

function Import-Tsv {
  param([string]$Path)

  return Import-Csv -LiteralPath $Path -Delimiter "`t" -Encoding UTF8
}

Assert-FileExists -Path $ProjectInfoPath -Label "Project information"
Assert-FileExists -Path $DonationPath -Label "Donation history"

if ([string]::IsNullOrWhiteSpace($Salt)) {
  $Salt = "gr23-local-demo-salt"
  Write-Host "GR23_REDACTION_SALT is not set. Using deterministic local demo salt." -ForegroundColor Yellow
  Write-Host "Set `$env:GR23_REDACTION_SALT for a private stable redaction map." -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$projects = Import-Tsv -Path $ProjectInfoPath
$donations = Import-Tsv -Path $DonationPath

$redactionMap = @{}
$projectIndex = @{}
$payoutWalletIndex = @{}

$redactedProjects = foreach ($project in $projects) {
  $projectId = Get-FieldValue -Row $project -Names @("projectId")
  $applicationId = Get-FieldValue -Row $project -Names @("id")
  $title = Get-FieldValue -Row $project -Names @("title")
  $status = Get-FieldValue -Row $project -Names @("status")
  $payoutAddress = Normalize-Address (Get-FieldValue -Row $project -Names @("payoutAddress"))
  $website = Get-FieldValue -Row $project -Names @("website")
  $projectGithub = Get-FieldValue -Row $project -Names @("projectGithub")
  $userGithub = Get-FieldValue -Row $project -Names @("userGithub")
  $teamSize = Get-FieldValue -Row $project -Names @("Team Size")
  $projectAge = Get-FieldValue -Row $project -Names @("How old is the project? (Months)")
  $pastWalletsText = Get-FieldValue -Row $project -Names @("If you participated in past grant rounds (i.e. DeSci GR15/ Beta/GG 20DeSci round/GG21 DeSci round) using a different project payout wallet address, please share it here.")

  $projectKey = New-RedactedId -Prefix "project_" -Value $projectId -Salt $Salt
  $payoutKey = New-RedactedId -Prefix "wallet_" -Value $payoutAddress -Salt $Salt

  Add-MapEntry -Map $redactionMap -Kind "projectId" -RawValue $projectId -RedactedValue $projectKey
  Add-MapEntry -Map $redactionMap -Kind "wallet" -RawValue $payoutAddress -RedactedValue $payoutKey

  $pastWallets = [regex]::Matches($pastWalletsText, "0x[a-fA-F0-9]{40}") |
    ForEach-Object { $_.Value.ToLowerInvariant() } |
    Select-Object -Unique

  $pastWalletKeys = foreach ($wallet in $pastWallets) {
    $walletKey = New-RedactedId -Prefix "wallet_" -Value $wallet -Salt $Salt
    Add-MapEntry -Map $redactionMap -Kind "past_payout_wallet" -RawValue $wallet -RedactedValue $walletKey
    $walletKey
  }

  if (-not [string]::IsNullOrWhiteSpace($projectId)) {
    $projectIndex[$projectId] = [ordered]@{
      project_key = $projectKey
      application_id = $applicationId
      title = $title
      payout_wallet = $payoutKey
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($payoutAddress)) {
    $payoutWalletIndex[$payoutAddress] = [ordered]@{
      project_key = $projectKey
      title = $title
    }
  }

  [pscustomobject][ordered]@{
    application_id = $applicationId
    project_key = $projectKey
    status = $status
    title = $title
    payout_wallet = $payoutKey
    website_present = -not [string]::IsNullOrWhiteSpace($website)
    project_github_present = -not [string]::IsNullOrWhiteSpace($projectGithub)
    user_github_present = -not [string]::IsNullOrWhiteSpace($userGithub)
    team_size = $teamSize
    project_age = $projectAge
    past_payout_wallets = @($pastWalletKeys)
  }
}

$redactedDonations = foreach ($donation in $donations) {
  $txHash = Normalize-Hash (Get-FieldValue -Row $donation -Names @("id", "transaction hash"))
  $projectId = Get-FieldValue -Row $donation -Names @("projectId")
  $applicationId = Get-FieldValue -Row $donation -Names @("applicationId")
  $roundId = Get-FieldValue -Row $donation -Names @("roundId")
  $token = Get-FieldValue -Row $donation -Names @("token")
  $voter = Normalize-Address (Get-FieldValue -Row $donation -Names @("voter"))
  $grantAddress = Normalize-Address (Get-FieldValue -Row $donation -Names @("grantAddress"))
  $amountUsd = Convert-ToDecimal (Get-FieldValue -Row $donation -Names @("amountUSD"))
  $coefficient = Convert-ToDecimal (Get-FieldValue -Row $donation -Names @("coefficient"))
  $status = Get-FieldValue -Row $donation -Names @("status")
  $timestamp = Get-FieldValue -Row $donation -Names @("last_score_timestamp")
  $checkType = Get-FieldValue -Row $donation -Names @("type")
  $success = Convert-ToBoolOrNull (Get-FieldValue -Row $donation -Names @("success"))
  $rawScore = Convert-ToDecimal (Get-FieldValue -Row $donation -Names @("rawScore")
  )
  $threshold = Convert-ToDecimal (Get-FieldValue -Row $donation -Names @("threshold")
  )

  $txKey = New-RedactedId -Prefix "tx_" -Value $txHash -Salt $Salt
  $projectKey = New-RedactedId -Prefix "project_" -Value $projectId -Salt $Salt
  $donorKey = New-RedactedId -Prefix "wallet_" -Value $voter -Salt $Salt
  $grantKey = New-RedactedId -Prefix "wallet_" -Value $grantAddress -Salt $Salt

  Add-MapEntry -Map $redactionMap -Kind "tx_hash" -RawValue $txHash -RedactedValue $txKey
  Add-MapEntry -Map $redactionMap -Kind "projectId" -RawValue $projectId -RedactedValue $projectKey
  Add-MapEntry -Map $redactionMap -Kind "wallet" -RawValue $voter -RedactedValue $donorKey
  Add-MapEntry -Map $redactionMap -Kind "wallet" -RawValue $grantAddress -RedactedValue $grantKey

  [pscustomobject][ordered]@{
    tx = $txKey
    project_key = $projectKey
    application_id = $applicationId
    round_id = $roundId
    token_key = New-RedactedId -Prefix "token_" -Value $token -Salt $Salt
    donor_wallet = $donorKey
    grant_wallet = $grantKey
    amount_usd = [Math]::Round($amountUsd, 6)
    coefficient = $coefficient
    status = $status
    last_score_timestamp = $timestamp
    check_type = $checkType
    passport_success = $success
    raw_score = $rawScore
    threshold = $threshold
  }
}

$projectDonationGroups = $redactedDonations | Group-Object -Property project_key
$donorGroups = $redactedDonations | Group-Object -Property donor_wallet
$failedThresholdCount = @($redactedDonations | Where-Object { $_.passport_success -eq $false }).Count

$projectSummaries = foreach ($group in $projectDonationGroups) {
  $rows = @($group.Group)
  $uniqueDonors = @($rows | Select-Object -ExpandProperty donor_wallet -Unique)
  $totalUsd = ($rows | Measure-Object -Property amount_usd -Sum).Sum
  $failedCount = @($rows | Where-Object { $_.passport_success -eq $false }).Count
  $projectMeta = $redactedProjects | Where-Object { $_.project_key -eq $group.Name } | Select-Object -First 1

  [pscustomobject][ordered]@{
    project_key = $group.Name
    title = if ($projectMeta) { $projectMeta.title } else { "" }
    donation_count = $rows.Count
    unique_donor_count = $uniqueDonors.Count
    total_amount_usd = [Math]::Round([double]$totalUsd, 6)
    failed_threshold_count = $failedCount
  }
}

$summary = [ordered]@{
  imported_at = (Get-Date).ToString("s")
  source_files = [ordered]@{
    project_info = Split-Path -Leaf $ProjectInfoPath
    donations = Split-Path -Leaf $DonationPath
  }
  privacy_mode = "redacted_outputs_with_private_local_map"
  project_count = @($redactedProjects).Count
  donation_count = @($redactedDonations).Count
  unique_donor_count = @($donorGroups | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) }).Count
  failed_threshold_count = $failedThresholdCount
  project_summaries = @($projectSummaries | Sort-Object -Property donation_count -Descending)
}

$publicOutput = [ordered]@{
  summary = $summary
  projects = @($redactedProjects)
  donations = @($redactedDonations)
}

$privateMapOutput = [ordered]@{
  generated_at = (Get-Date).ToString("s")
  warning = "Private local redaction map. Do not commit publicly."
  entries = $redactionMap.GetEnumerator() |
    Sort-Object -Property Name |
    ForEach-Object {
      [ordered]@{
        raw = $_.Key
        kind = $_.Value.kind
        redacted = $_.Value.redacted
      }
    }
}

$redactedPath = Join-Path $OutDir "gr23-redacted-data.json"
$summaryPath = Join-Path $OutDir "gr23-import-summary.json"
$privateMapPath = Join-Path $OutDir "gr23-redaction-map.private.json"

$publicOutput | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $redactedPath -Encoding UTF8
$summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
$privateMapOutput | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $privateMapPath -Encoding UTF8

Write-Host "GR23 import complete." -ForegroundColor Cyan
Write-Host "Projects:  $(@($redactedProjects).Count)"
Write-Host "Donations: $(@($redactedDonations).Count)"
Write-Host "Unique donors: $($summary.unique_donor_count)"
Write-Host "Failed threshold donations: $failedThresholdCount"
Write-Host ""
Write-Host "Redacted data: $redactedPath"
Write-Host "Summary:       $summaryPath"
Write-Host "Private map:   $privateMapPath"
Write-Host ""
Write-Host "Do not commit files under outputs/gr23-integrity unless explicitly reviewed." -ForegroundColor Yellow
