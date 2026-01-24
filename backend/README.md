# Backend Services - HDuce Medical Platform

## Overview
The backend of HDuce Medical Platform consists of 6 microservices built with FastAPI and Python 3.11. Each service is independently deployable and follows microservices architecture principles.

## Services Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    API Gateway                      │
│                  (NGINX Reverse Proxy)              │
└─────┬───────────────────┬───────────────────┬──────┘
      │                   │                   │
┌─────▼─────┐     ┌──────▼──────┐     ┌──────▼──────┐
│   Auth    │     │    User     │     │ Appointment │
│  (8000)   │     │   (8001)    │     │   (8002)    │
└─────┬─────┘     └──────┬──────┘     └──────┬──────┘
      │                   │                   │
┌─────▼───────────────────▼───────────────────▼──────┐
│              Notification Service                   │
│                      (8003)                         │
└─────┬───────────────────┬───────────────────┬──────┘
      │                   │                   │
┌─────▼─────┐     ┌──────▼──────┐     ┌──────▼──────┐
│   MQTT    │     │   Metrics   │     │  Database   │
│  (8004)   │     │   (8005)    │     │   Layer     │
└───────────┘     └─────────────┘     └─────────────┘
```

## Service Details

| Service | Port | Database | Description |
|---------|------|----------|-------------|
| Auth Service | 8000 | auth_db | Authentication & authorization |
| User Service | 8001 | user_db | User profile management |
| Appointment Service | 8002 | appointment_db | Medical appointment scheduling |
| Notification Service | 8003 | notification_db | Email/SMS/Push notifications |
| MQTT Service | 8004 | mqtt_db | IoT device integration |
| Metrics Service | 8005 | metrics_db | System metrics & analytics |

## Shared Libraries

All services use shared libraries located in `../shared-libraries/`:

### Database Module

```python
from hduce_shared.database import Base
from hduce_shared.database.postgres import get_db

# Usage in services:
class User(Base):
    __tablename__ = "users"
    # ... model definition
```

### Authentication Module

```python
from hduce_shared.auth.jwt_manager import JWTManager
from hduce_shared.auth.dependencies import get_current_user

# Usage:
jwt_manager = JWTManager(secret_key="your-secret")
token = jwt_manager.create_token(data={"user_id": 1})
```

## Development Setup

### Prerequisites
- Python 3.11+
- PostgreSQL 15+
- Docker & Docker Compose
- Git

### Local Development

**Start all services with Docker Compose:**

```bash
docker-compose up -d
```

**Start individual service for development:**

```bash
cd backend/auth-service
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
pip install -e ../../shared-libraries
uvicorn main:app --reload --port 8000
```

### Testing

```bash
# Run tests for a specific service
cd backend/auth-service
pytest tests/

# Run tests with coverage
pytest --cov=src tests/

# Run all backend tests
cd backend
pytest --collect-only | findstr "test" | Measure-Object
```

## Database Management

### Database URLs

Each service connects to its own database:

```env
# Auth Service
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_db

# User Service
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/user_db

# etc...
```

### Database Migrations

```bash
# Using Alembic (if configured)
alembic upgrade head

# Manual SQL
docker exec -it hduce-postgres psql -U postgres -d auth_db -c "SELECT * FROM users;"
```

## API Documentation

Each service provides auto-generated OpenAPI documentation:

```bash
# Access Swagger UI
http://localhost:8000/docs  # Auth Service
http://localhost:8001/docs  # User Service
http://localhost:8002/docs  # Appointment Service
http://localhost:8003/docs  # Notification Service
http://localhost:8004/docs  # MQTT Service
http://localhost:8005/docs  # Metrics Service

# Access ReDoc
http://localhost:8000/redoc
```

## Docker Configuration

### Local Development Dockerfiles
Each service has a `Dockerfile` for local development with hot reload.

### AWS Deployment Dockerfiles
Each service has a `Dockerfile.aws` optimized for production deployment with:
- Multi-stage builds
- Python dependency caching
- Shared libraries integration
- Security hardening

## Environment Variables

### Common to All Services

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/DB_NAME

# JWT (CRITICAL - DO NOT CHANGE)
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
TOKEN_EXPIRY=24h

# Logging
LOG_LEVEL=INFO
DEBUG=false
```

### Service-Specific Variables
Check each service's README for specific environment variables.

## Deployment

### Local Deployment

```bash
docker-compose up -d --build
```

### AWS Deployment
See `../hduce-deployment-aws/README.md` for AWS deployment instructions.

## Monitoring & Health Checks

### Health Check Endpoints
All services provide:
- `GET /health` - Basic health check
- `GET /health/detailed` - Detailed health with dependencies

### Metrics Endpoints
- `GET /metrics` - Prometheus metrics (if configured)

## Troubleshooting

### Common Issues

**Import Errors with Shared Libraries**

```bash
# Ensure shared-libraries are installed
pip install -e ../../shared-libraries

# Check PYTHONPATH
echo $PYTHONPATH
# Should include: /app:/app/shared-libraries
```

**Database Connection Issues**

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
python -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/postgres')
    print('Connection successful')
    conn.close()
except Exception as e:
    print(f'Connection failed: {e}')
"
```

**Port Conflicts**

```bash
# Check which services are using ports 8000-8005
netstat -ano | findstr :800

# Or with PowerShell
Get-NetTCPConnection -LocalPort 8000,8001,8002,8003,8004,8005
```

### Logs

```bash
# View logs for all services
docker-compose logs

# View logs for specific service
docker-compose logs auth-service

# Follow logs in real-time
docker-compose logs -f auth-service user-service
```

## Contributing

### Code Standards
- Follow PEP 8 for Python code
- Use type hints extensively
- Write comprehensive docstrings
- Include unit tests for new features

### Development Workflow
1. Create feature branch
2. Implement changes with tests
3. Update documentation
4. Create pull request
5. Code review and merge

---

**Backend Version**: 1.0.0