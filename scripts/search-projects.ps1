param(
  [string]$Query,
  [string]$ProjectsPath = ".\data\projects.json",
  [int]$Top = 10
)

$ErrorActionPreference = "Stop"

if (-not $Query) {
  Write-Error "Missing -Query. Example: .\scripts\search-projects.ps1 -Query rare"
}

if (-not (Test-Path -LiteralPath $ProjectsPath)) {
  Write-Error "Projects file not found: $ProjectsPath. Run .\scripts\import-spark-data.ps1 first."
}

function Normalize-Text {
  param([string]$Text)

  if (-not $Text) {
    return ""
  }

  return $Text.ToLowerInvariant()
}

function Add-Weighted-Term {
  param(
    [System.Collections.Generic.List[object]]$Terms,
    [string]$Term,
    [double]$Multiplier
  )

  if ($Term) {
    $Terms.Add([ordered]@{
      term = $Term
      multiplier = $Multiplier
    })
  }
}

function Expand-Query-Terms {
  param([string]$InputQuery)

  $terms = New-Object System.Collections.Generic.List[object]
  $rawTerms = (Normalize-Text $InputQuery).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

  foreach ($term in $rawTerms) {
    Add-Weighted-Term -Terms $terms -Term $term -Multiplier 1.0

    switch ($term) {
      "ai" {
        Add-Weighted-Term -Terms $terms -Term "llm" -Multiplier 0.35
        Add-Weighted-Term -Terms $terms -Term "model" -Multiplier 0.25
        Add-Weighted-Term -Terms $terms -Term "machine learning" -Multiplier 0.35
      }
      "llm" {
        Add-Weighted-Term -Terms $terms -Term "ai" -Multiplier 0.35
        Add-Weighted-Term -Terms $terms -Term "model" -Multiplier 0.25
      }
      "evaluator" {
        Add-Weighted-Term -Terms $terms -Term "evaluators" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluation" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluate" -Multiplier 0.7
      }
      "evaluators" {
        Add-Weighted-Term -Terms $terms -Term "evaluator" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluation" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluate" -Multiplier 0.7
      }
      "evaluation" {
        Add-Weighted-Term -Terms $terms -Term "evaluator" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluators" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "evaluate" -Multiplier 0.7
      }
      "funding" {
        Add-Weighted-Term -Terms $terms -Term "fund" -Multiplier 0.5
        Add-Weighted-Term -Terms $terms -Term "proposal" -Multiplier 0.7
        Add-Weighted-Term -Terms $terms -Term "proposals" -Multiplier 0.7
        Add-Weighted-Term -Terms $terms -Term "pgf" -Multiplier 0.7
        Add-Weighted-Term -Terms $terms -Term "public goods funding" -Multiplier 0.8
      }
      "desci" {
        Add-Weighted-Term -Terms $terms -Term "decentralized science" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "science" -Multiplier 0.4
      }
      "bio" {
        Add-Weighted-Term -Terms $terms -Term "biology" -Multiplier 0.8
        Add-Weighted-Term -Terms $terms -Term "biotech" -Multiplier 0.7
        Add-Weighted-Term -Terms $terms -Term "health" -Multiplier 0.5
      }
    }
  }

  $deduped = @{}
  foreach ($item in $terms) {
    if ((-not $deduped.ContainsKey($item.term)) -or $item.multiplier -gt $deduped[$item.term].multiplier) {
      $deduped[$item.term] = $item
    }
  }

  return @($deduped.Values)
}

function Add-Field-Score {
  param(
    [string]$FieldValue,
    [object[]]$Terms,
    [int]$Weight
  )

  $text = Normalize-Text $FieldValue
  $score = 0
  $hits = New-Object System.Collections.Generic.List[string]

  if (-not $text) {
    return [ordered]@{ score = 0; hits = @() }
  }

  foreach ($termSpec in $Terms) {
    $term = $termSpec.term
    $multiplier = [double]$termSpec.multiplier

    if ($text.Contains($term)) {
      $score += ($Weight * $multiplier)
      $hits.Add($term)
    }
  }

  return [ordered]@{
    score = $score
    hits = @($hits | Select-Object -Unique)
  }
}

$dataset = Get-Content -LiteralPath $ProjectsPath -Raw | ConvertFrom-Json
$terms = Expand-Query-Terms $Query
$normalizedQuery = Normalize-Text $Query

$matches = foreach ($project in $dataset.projects) {
  $score = 0
  $matchedFields = New-Object System.Collections.Generic.List[object]

  $projectEntityId = $project.PSObject.Properties["project_entity_id"].Value
  $participationId = $project.PSObject.Properties["participation_id"].Value
  $projectName = $project.PSObject.Properties["project_name"].Value
  $domain = $project.PSObject.Properties["domain"].Value
  $projectType = $project.PSObject.Properties["project_type"].Value
  $what = $project.PSObject.Properties["what_are_you_making"].Value
  $link = $project.PSObject.Properties["link"].Value
  $functionValue = $project.PSObject.Properties["function"].Value
  $impact = $project.PSObject.Properties["impact"].Value
  $progress = $project.PSObject.Properties["progress"].Value
  $tags = $project.PSObject.Properties["tags"].Value
  $whyYou = $project.PSObject.Properties["why_you"].Value
  $rawText = $project.PSObject.Properties["raw_text"].Value

  $idText = Normalize-Text "$projectEntityId $participationId"
  if ($idText.Contains($normalizedQuery)) {
    $score += 100
    $matchedFields.Add([ordered]@{ field = "id"; hits = @($normalizedQuery); weight = 100 })
  }

  $fieldWeights = @(
    @{ name = "project_name"; value = $projectName; weight = 12 },
    @{ name = "what_are_you_making"; value = $what; weight = 8 },
    @{ name = "domain"; value = $domain; weight = 6 },
    @{ name = "function"; value = $functionValue; weight = 5 },
    @{ name = "impact"; value = $impact; weight = 4 },
    @{ name = "progress"; value = $progress; weight = 4 },
    @{ name = "project_type"; value = $projectType; weight = 3 },
    @{ name = "tags"; value = $tags; weight = 3 },
    @{ name = "why_you"; value = $whyYou; weight = 2 },
    @{ name = "raw_text"; value = $rawText; weight = 1 }
  )

  foreach ($field in $fieldWeights) {
    $result = Add-Field-Score -FieldValue $field.value -Terms $terms -Weight $field.weight
    if ($result.score -gt 0) {
      $score += $result.score
      $matchedFields.Add([ordered]@{
        field = $field.name
        hits = $result.hits
        weight = $field.weight
      })
    }
  }

  if ($score -gt 0) {
    $matchedFieldItems = @($matchedFields.ToArray())

    [ordered]@{
      score = [Math]::Round($score, 2)
      project_entity_id = $projectEntityId
      participation_id = $participationId
      project_name = $projectName
      domain = $domain
      project_type = $projectType
      what_are_you_making = $what
      link = $link
      matched_fields = $matchedFieldItems
    }
  }
}

$sortedMatches = @($matches | Sort-Object -Property { $_.score } -Descending)
@($sortedMatches | Select-Object -First $Top) | ConvertTo-Json -Depth 20
