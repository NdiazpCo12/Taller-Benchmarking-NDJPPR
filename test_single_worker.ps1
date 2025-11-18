param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("java", "python", "nodejs", "go")]
    [string]$Worker
)

$ErrorActionPreference = "Stop"

$workerConfig = @{
    "java" = @{name="Java Spring"; port=5001; path="worker_java_spring"; healthPath="/api/health"}
    "python" = @{name="Python Flask"; port=5002; path="worker_python_flask"; healthPath="/health"}
    "nodejs" = @{name="Node.js NestJS"; port=5003; path="worker_nodejs_nestjs"; healthPath="/api/health"}
    "go" = @{name="Go Gin"; port=5004; path="worker_go_gin"; healthPath="/health"}
}

$config = $workerConfig[$Worker]

Write-Host "=== Testing $($config.name) ===" -ForegroundColor Cyan

$testJson = @"
{
  "customerId": "C123",
  "items": [
    {"productId": "P1", "quantity": 2, "price": 10.5},
    {"productId": "P2", "quantity": 1, "price": 5.0}
  ]
}
"@

Write-Host "Starting containers..." -ForegroundColor Yellow
Set-Location $config.path
docker compose up -d

Write-Host "Waiting for service to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 15

$maxRetries = 30
$retryCount = 0
$isReady = $false

while ($retryCount -lt $maxRetries -and -not $isReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($config.port)$($config.healthPath)" -Method GET -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $isReady = $true
            Write-Host "Service is ready!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "Waiting... ($retryCount/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $isReady) {
    Write-Host "Service did not become ready. Check logs with: docker compose logs" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "`nTesting POST /api/orders..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:$($config.port)/api/orders" `
        -Method POST `
        -ContentType "application/json" `
        -Body $testJson
    
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "`nResponse:" -ForegroundColor Cyan
    $response | ConvertTo-Json | Write-Host
    
    Write-Host "`nExpected: totalAmount=26.0, itemsCount=3" -ForegroundColor Gray
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`nContainers are still running. To stop them, run:" -ForegroundColor Gray
Write-Host "  cd $($config.path)" -ForegroundColor Gray
Write-Host "  docker compose down" -ForegroundColor Gray

Set-Location ..

