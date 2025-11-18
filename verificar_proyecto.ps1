Write-Host "=== Verificación del Proyecto ===" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

$workers = @("worker_java_spring", "worker_python_flask", "worker_nodejs_nestjs", "worker_go_gin")

foreach ($worker in $workers) {
    Write-Host "Verificando $worker..." -ForegroundColor Yellow
    
    if (-not (Test-Path $worker)) {
        Write-Host "  ERROR: Carpeta $worker no existe" -ForegroundColor Red
        $errors++
        continue
    }
    
    # Verificar docker-compose.yml
    if (-not (Test-Path "$worker\docker-compose.yml")) {
        Write-Host "  ERROR: docker-compose.yml no existe" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "  ✓ docker-compose.yml existe" -ForegroundColor Green
    }
    
    # Verificar Dockerfile
    if (-not (Test-Path "$worker\Dockerfile")) {
        Write-Host "  ERROR: Dockerfile no existe" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "  ✓ Dockerfile existe" -ForegroundColor Green
    }
    
    # Verificar init.sql
    if (-not (Test-Path "$worker\init.sql")) {
        Write-Host "  ERROR: init.sql no existe" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "  ✓ init.sql existe" -ForegroundColor Green
    }
    
    # Verificaciones específicas por worker
    switch ($worker) {
        "worker_java_spring" {
            if (-not (Test-Path "$worker\pom.xml")) {
                Write-Host "  ERROR: pom.xml no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ pom.xml existe" -ForegroundColor Green
            }
            if (-not (Test-Path "$worker\src\main\java")) {
                Write-Host "  ERROR: Código fuente Java no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ Código fuente Java existe" -ForegroundColor Green
            }
        }
        "worker_python_flask" {
            if (-not (Test-Path "$worker\app.py")) {
                Write-Host "  ERROR: app.py no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ app.py existe" -ForegroundColor Green
            }
            if (-not (Test-Path "$worker\requirements.txt")) {
                Write-Host "  ERROR: requirements.txt no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ requirements.txt existe" -ForegroundColor Green
            }
        }
        "worker_nodejs_nestjs" {
            if (-not (Test-Path "$worker\package.json")) {
                Write-Host "  ERROR: package.json no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ package.json existe" -ForegroundColor Green
            }
            if (-not (Test-Path "$worker\src")) {
                Write-Host "  ERROR: Código fuente TypeScript no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ Código fuente TypeScript existe" -ForegroundColor Green
            }
        }
        "worker_go_gin" {
            if (-not (Test-Path "$worker\go.mod")) {
                Write-Host "  ERROR: go.mod no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ go.mod existe" -ForegroundColor Green
            }
            if (-not (Test-Path "$worker\main.go")) {
                Write-Host "  ERROR: main.go no existe" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "  ✓ main.go existe" -ForegroundColor Green
            }
        }
    }
    
    Write-Host ""
}

# Verificar README
if (Test-Path "README.md") {
    Write-Host "✓ README.md existe" -ForegroundColor Green
} else {
    Write-Host "WARNING: README.md no existe" -ForegroundColor Yellow
    $warnings++
}

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "✓ Proyecto verificado correctamente" -ForegroundColor Green
    if ($warnings -gt 0) {
        Write-Host "⚠ $warnings advertencia(s)" -ForegroundColor Yellow
    }
    exit 0
} else {
    Write-Host "✗ Se encontraron $errors error(es)" -ForegroundColor Red
    exit 1
}

