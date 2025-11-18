$ErrorActionPreference = "Stop"

Write-Host "=== Testing Workers ===" -ForegroundColor Cyan

$workers = @(
    @{name="Java Spring"; port=5001; path="worker_java_spring"},
    @{name="Python Flask"; port=5002; path="worker_python_flask"},
    @{name="Node.js NestJS"; port=5003; path="worker_nodejs_nestjs"},
    @{name="Go Gin"; port=5004; path="worker_go_gin"}
)

$testJson = @"
{
  "customerId": "C123",
  "items": [
    {"productId": "P1", "quantity": 2, "price": 10.5},
    {"productId": "P2", "quantity": 1, "price": 5.0}
  ]
}
"@

foreach ($worker in $workers) {
    Write-Host "`n--- Testing $($worker.name) (Port $($worker.port)) ---" -ForegroundColor Yellow
    
    Write-Host "Starting containers..." -ForegroundColor Gray
    Set-Location $worker.path
    docker compose up -d
    
    Write-Host "Waiting for service to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    $maxRetries = 30
    $retryCount = 0
    $isReady = $false
    
    while ($retryCount -lt $maxRetries -and -not $isReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$($worker.port)/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $isReady = $true
                Write-Host "Service is ready!" -ForegroundColor Green
            }
        } catch {
            $retryCount++
            Start-Sleep -Seconds 2
        }
    }
    
    if (-not $isReady) {
        Write-Host "Service did not become ready in time. Skipping..." -ForegroundColor Red
        Set-Location ..
        continue
    }
    
    Write-Host "Testing POST /api/orders..." -ForegroundColor Gray
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$($worker.port)/api/orders" `
            -Method POST `
            -ContentType "application/json" `
            -Body $testJson
        
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    } catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "Stopping containers..." -ForegroundColor Gray
    docker compose down
    Set-Location ..
}

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan

