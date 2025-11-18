# Taller de Benchmarking con JMeter

Proyecto de benchmarking de APIs con PostgreSQL usando JMeter.


El proyecto contiene 4 workers/microservicios implementados en diferentes tecnologías:

- `worker_java_spring` - Java con Spring Boot (Puerto: 5001, DB: 5433)
- `worker_python_flask` - Python con Flask (Puerto: 5002, DB: 5434)
- `worker_nodejs_nestjs` - Node.js con NestJS (Puerto: 5003, DB: 5435)
- `worker_go_gin` - Go con Gin (Puerto: 5004, DB: 5436)

## Endpoint Común

Todos los workers implementan el mismo endpoint:

**POST /api/orders**

### Entrada (JSON):
```json
{
  "customerId": "C123",
  "items": [
    { "productId": "P1", "quantity": 2, "price": 10.5 },
    { "productId": "P2", "quantity": 1, "price": 5.0 }
  ]
}
```

### Funcionalidad:
- Calcula `totalAmount` y `itemsCount`
- Inserta datos en PostgreSQL en dos tablas: `orders` y `order_items`
- Retorna JSON con `orderId`, totales y fecha de procesamiento

### Respuesta (JSON):
```json
{
  "orderId": "ORD-ABC12345",
  "totalAmount": 26.0,
  "itemsCount": 3,
  "processedAt": "2024-01-15T10:30:00"
}
```

## Base de Datos

Cada worker tiene su propia instancia de PostgreSQL con las siguientes tablas:

### Tabla `orders`:
- `id` (SERIAL PRIMARY KEY)
- `order_id` (VARCHAR(50) UNIQUE NOT NULL)
- `customer_id` (VARCHAR(50) NOT NULL)
- `total_amount` (NUMERIC(10,2) NOT NULL)
- `items_count` (INT NOT NULL)
- `created_at` (TIMESTAMP NOT NULL DEFAULT NOW())

### Tabla `order_items`:
- `id` (SERIAL PRIMARY KEY)
- `order_id` (VARCHAR(50) NOT NULL)
- `product_id` (VARCHAR(50) NOT NULL)
- `quantity` (INT NOT NULL)
- `price` (NUMERIC(10,2) NOT NULL)

## Ejecución

Cada worker tiene su propio `docker-compose.yml`. Para ejecutar un worker:

```bash
cd worker_java_spring
docker compose up -d
```

O para cualquier otro worker:
```bash
cd worker_python_flask
docker compose up -d
```

Para detener un worker:
```bash
docker compose down
```

## Pruebas

### Java Spring (Puerto 5001):
```bash
curl -X POST http://localhost:5001/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "C123",
    "items": [
      {"productId": "P1", "quantity": 2, "price": 10.5},
      {"productId": "P2", "quantity": 1, "price": 5.0}
    ]
  }'
```

### Python Flask (Puerto 5002):
```bash
curl -X POST http://localhost:5002/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "C123",
    "items": [
      {"productId": "P1", "quantity": 2, "price": 10.5},
      {"productId": "P2", "quantity": 1, "price": 5.0}
    ]
  }'
```

### Node.js NestJS (Puerto 5003):
```bash
curl -X POST http://localhost:5003/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "C123",
    "items": [
      {"productId": "P1", "quantity": 2, "price": 10.5},
      {"productId": "P2", "quantity": 1, "price": 5.0}
    ]
  }'
```

### Go Gin (Puerto 5004):
```bash
curl -X POST http://localhost:5004/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "C123",
    "items": [
      {"productId": "P1", "quantity": 2, "price": 10.5},
      {"productId": "P2", "quantity": 1, "price": 5.0}
    ]
  }'
```

## Health Check

Todos los workers tienen un endpoint de health check:
- Java Spring: `GET http://localhost:5001/api/health`
- Python Flask: `GET http://localhost:5002/health`
- Node.js NestJS: `GET http://localhost:5003/api/health`
- Go Gin: `GET http://localhost:5004/health`

## Pruebas con JMeter

Para realizar las pruebas de carga, crea un Test Plan en JMeter con:

### Configuración del Test Plan

1. **Thread Group**:
   - Baja carga: 10 usuarios, Ramp-up: 10s, Duración: 60s
   - Media carga: 50 usuarios, Ramp-up: 30s, Duración: 120s
   - Alta carga: 100 usuarios, Ramp-up: 60s, Duración: 180s

2. **HTTP Request Defaults**:
   - Server: localhost
   - Port: [5001, 5002, 5003 o 5004 según el worker]
   - Path: /api/orders

3. **HTTP Header Manager**:
   - Content-Type: application/json

4. **HTTP Request**:
   - Method: POST
   - Body Data:
   ```json
   {
     "customerId": "C123",
     "items": [
       {"productId": "P1", "quantity": 2, "price": 10.5},
       {"productId": "P2", "quantity": 1, "price": 5.0}
     ]
   }
   ```

5. **Listeners**:
   - Summary Report
   - Aggregate Report

### Métricas a Registrar

Para cada escenario, registra:
- Average Response Time (ms)
- Percentil 95 (P95)
- Throughput (requests/second)
- % de Errores

## Notas

- Cada worker usa puertos diferentes para evitar conflictos
- Cada worker tiene su propia base de datos PostgreSQL en un puerto diferente
- Las tablas se crean automáticamente al iniciar el contenedor de PostgreSQL mediante el script `init.sql`
- Todos los workers implementan la misma lógica de negocio para permitir comparaciones justas en el benchmarking

