param(
  [string]$Model = "glm-5.1",
  [string]$Prompt = "Say hello and confirm you are GLM-5.1."
)

$ErrorActionPreference = "Stop"

if (-not $env:ZAI_API_KEY) {
  Write-Error "Missing ZAI_API_KEY. Set it first: `$env:ZAI_API_KEY='your_api_key'"
}

$body = @{
  model = $Model
  messages = @(
    @{ role = "user"; content = $Prompt }
  )
  thinking = @{ type = "enabled" }
  max_tokens = 512
  temperature = 0.7
  stream = $false
} | ConvertTo-Json -Depth 20

$headers = @{
  "Authorization" = "Bearer $env:ZAI_API_KEY"
  "Content-Type" = "application/json"
}

try {
  $response = Invoke-RestMethod `
    -Uri "https://api.z.ai/api/paas/v4/chat/completions" `
    -Method Post `
    -Headers $headers `
    -Body $body
} catch {
  Write-Host "Z.AI request failed." -ForegroundColor Red
  Write-Host "Model: $Model"

  if ($_.Exception.Response) {
    Write-Host "HTTP status: $([int]$_.Exception.Response.StatusCode) $($_.Exception.Response.StatusDescription)"

    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
      $reader = New-Object System.IO.StreamReader($stream)
      $errorBody = $reader.ReadToEnd()
      if ($errorBody) {
        Write-Host "Response body:"
        Write-Host $errorBody
      }
    }
  } else {
    Write-Host $_.Exception.Message
  }

  exit 1
}

Write-Host "Model response:"
Write-Host $response.choices[0].message.content
