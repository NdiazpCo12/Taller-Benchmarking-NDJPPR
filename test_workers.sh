#!/bin/bash

echo "=== Testing Workers ==="

test_worker() {
    local name=$1
    local port=$2
    local path=$3
    local health_path=$4
    
    echo ""
    echo "--- Testing $name (Port $port) ---"
    
    cd "$path" || exit 1
    
    echo "Starting containers..."
    docker compose up -d
    
    echo "Waiting for service to be ready..."
    sleep 15
    
    max_retries=30
    retry_count=0
    is_ready=false
    
    while [ $retry_count -lt $max_retries ] && [ "$is_ready" = false ]; do
        if curl -s -f "http://localhost:$port$health_path" > /dev/null 2>&1; then
            is_ready=true
            echo "Service is ready!"
        else
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done
    
    if [ "$is_ready" = false ]; then
        echo "Service did not become ready. Skipping..."
        docker compose down
        cd ..
        return
    fi
    
    echo "Testing POST /api/orders..."
    response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:$port/api/orders" \
        -H "Content-Type: application/json" \
        -d '{
            "customerId": "C123",
            "items": [
                {"productId": "P1", "quantity": 2, "price": 10.5},
                {"productId": "P2", "quantity": 1, "price": 5.0}
            ]
        }')
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        echo "SUCCESS!"
        echo "Response: $body" | jq .
    else
        echo "FAILED: HTTP $http_code"
        echo "Response: $body"
    fi
    
    echo "Stopping containers..."
    docker compose down
    cd ..
}

test_worker "Java Spring" 5001 "worker_java_spring" "/api/health"
test_worker "Python Flask" 5002 "worker_python_flask" "/health"
test_worker "Node.js NestJS" 5003 "worker_nodejs_nestjs" "/api/health"
test_worker "Go Gin" 5004 "worker_go_gin" "/health"

echo ""
echo "=== Testing Complete ==="

