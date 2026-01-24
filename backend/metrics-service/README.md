# Metrics Service

## Overview
Metrics collection and analytics service for tracking platform performance, user engagement, and system health.

## Service Information
- **Port**: 8005
- **Database**: metrics_db (PostgreSQL)
- **Directory**: `backend/metrics-service`

## API Endpoints

### GET /metrics/summary
Get metrics summary dashboard.

```http
GET /metrics/summary
Authorization: Bearer <jwt_token>
```

### GET /metrics/services/health
Get health status of all services.

```http
GET /metrics/services/health
Authorization: Bearer <jwt_token>
```

### POST /metrics/events
Record a new event.

```http
POST /metrics/events
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "event_type": "user_login",
    "user_id": 1,
    "metadata": {"browser": "chrome", "ip": "192.168.1.1"}
}
```

### GET /metrics/dashboard
Get complete analytics dashboard data.

```http
GET /metrics/dashboard
Authorization: Bearer <jwt_token>
```

## Database Schema

```sql
-- System metrics
CREATE TABLE system_metrics (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tags JSONB DEFAULT '{}'
);

-- User events
CREATE TABLE user_events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    event_type VARCHAR(100) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- API metrics
CREATE TABLE api_metrics (
    id SERIAL PRIMARY KEY,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    response_time_ms INTEGER,
    user_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Dependencies
- Redis (for caching metrics)
- All other services (for collecting metrics)

## Events
- **Produces**: metrics.alert (when thresholds exceeded)
- **Consumes**: All service events

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/metrics_db

# Service
PORT=8005
LOG_LEVEL=INFO

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Metrics Configuration
METRICS_RETENTION_DAYS=90
METRICS_AGGREGATION_INTERVAL=300  # seconds
ALERT_THRESHOLD_ERROR_RATE=0.05  # 5%
ALERT_THRESHOLD_RESPONSE_TIME=2000  # ms
```

## Collected Metrics

### System Metrics
- CPU usage per service
- Memory consumption
- Database connection pool stats
- Request rate
- Error rate
- Response times

### User Metrics
- Active users (daily, weekly, monthly)
- User registrations
- Login frequency
- Feature usage
- Session duration

### API Metrics
- Requests per endpoint
- Response times
- Status code distribution
- Error rates
- Payload sizes

### Business Metrics
- Appointments created
- Notifications sent
- Device registrations
- Patient engagement

## Local Development

```bash
# Navigate to service directory
cd backend/metrics-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8005
```

## Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

## Docker

```bash
# Build image
docker build -t metrics-service .

# Run container
docker run -p 8005:8005 --env-file .env metrics-service
```

## API Documentation
- Swagger UI: http://localhost:8005/docs
- ReDoc: http://localhost:8005/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information

## Dashboard Queries

### Get daily active users
```sql
SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as active_users
FROM user_events
WHERE event_type = 'user_login'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Get service health
```sql
SELECT service_name, 
       AVG(value) as avg_response_time,
       COUNT(*) as request_count
FROM system_metrics
WHERE metric_name = 'response_time'
  AND timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY service_name;
```

## Prometheus Integration

Metrics are also exposed in Prometheus format:

```
GET /metrics/prometheus
```

Example output:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/users",status="200"} 1234

# HELP http_request_duration_seconds HTTP request latency
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 95
http_request_duration_seconds_bucket{le="0.5"} 120
```

## Alerting

Configure alerts in `config/alerts.yaml`:

```yaml
alerts:
  - name: high_error_rate
    condition: error_rate > 0.05
    severity: critical
    notification: email,slack
    
  - name: slow_response_time
    condition: avg_response_time > 2000
    severity: warning
    notification: slack
```