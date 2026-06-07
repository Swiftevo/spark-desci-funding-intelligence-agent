param(
  [string]$Query,
  [string]$OutPath
)

$ErrorActionPreference = "Stop"

if (-not $Query) {
  Write-Error "Missing -Query. Example: .\scripts\search-aminer-context.ps1 -Query 'AI funding evaluation'"
}

$topic = $Query.Trim()

$context = [ordered]@{
  mode = "dummy_aminer"
  query = $topic
  source = "AMiner placeholder adapter"
  note = "Replace this dummy adapter with AMiner search / literature survey output when API or export access is available."
  field_maturity = if ($topic -match "AI|LLM|Data") { "emerging_to_active" } elseif ($topic -match "Biotech|Health|Bio") { "active_research_area" } else { "needs_literature_check" }
  related_literature_placeholders = @(
    [ordered]@{
      title = "AMiner result placeholder 1"
      relevance = "Would summarize a closely related academic paper or scholar profile."
      citation_status = "not_verified_dummy"
    },
    [ordered]@{
      title = "AMiner result placeholder 2"
      relevance = "Would capture research trend, field maturity, or known controversy."
      citation_status = "not_verified_dummy"
    }
  )
  scientific_context = "Dummy AMiner context for '$topic'. In the real version, this section will use AMiner's academic search, literature survey, citation network, and scholar profile data to ground proposal review."
  credibility_questions = @(
    "What peer-reviewed or preprint literature supports the central claim?",
    "Is the proposed method novel, or mainly an application of known methods?",
    "Are there known limitations, benchmark issues, or reproducibility concerns in this research area?"
  )
}

$json = $context | ConvertTo-Json -Depth 20

if ($OutPath) {
  $json | Set-Content -LiteralPath $OutPath -Encoding UTF8
  Write-Host "AMiner dummy context written to $OutPath"
}

$json
