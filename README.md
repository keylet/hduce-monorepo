# 🏥 HDuce Medical Platform - Monorepo

## 📋 Overview
HDuce is a comprehensive medical platform built with microservices architecture using FastAPI, React, and Docker. The platform includes patient management, appointment scheduling, notifications, and IoT integration for medical devices.

## 🏗️ Architecture

### Technology Stack
- **Backend**: Python 3.11 + FastAPI + PostgreSQL
- **Frontend**: React + TypeScript + Vite
- **Message Queue**: RabbitMQ + Redis
- **IoT**: MQTT (Mosquitto) + Custom MQTT Service
- **Monitoring**: Prometheus + Grafana + n8n
- **Infrastructure**: Docker + Docker Compose + Terraform (AWS)

### Microservices Architecture
```
┌─────────────────────────────────────────────────────┐
│              React Frontend                          │
└──────────────────────────┬──────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────┐
│           NGINX Reverse Proxy                        │
└─────┬───────────────────┬───────────────────┬──────┘
      │                   │                   │
┌─────▼─────┐       ┌──────▼──────┐    ┌──────▼──────┐
│   Auth    │       │    User     │    │ Appointment │
│  Service  │       │   Service   │    │   Service   │
└─────┬─────┘       └──────┬──────┘    └──────┬──────┘
      │                    │                   │
┌─────▼───────────────────▼───────────────────▼──────┐
│           Notification Service                      │
└─────┬───────────────────┬───────────────────┬──────┘
      │                   │                   │
┌─────▼─────┐       ┌──────▼──────┐    ┌──────▼──────┐
│   MQTT    │       │   Metrics   │    │  Database   │
│  Service  │       │   Service   │    │    Layer    │
└───────────┘       └─────────────┘    └─────────────┘
```

## 📁 Project Structure
```
hduce-monorepo/
├── backend/                        # Microservices backend
│   ├── auth-service/              # Authentication & Authorization (8000)
│   ├── user-service/              # User Management (8001)
│   ├── appointment-service/       # Appointment Scheduling (8002)
│   ├── notification-service/      # Notifications (8003)
│   ├── mqtt-service/              # MQTT Integration (8004)
│   └── metrics-service/           # Metrics Collection (8005)
├── frontend/                      # React frontend application
├── shared-libraries/              # Shared Python libraries
├── nginx/                         # NGINX configuration
├── docker-compose.yml             # Local development setup
├── hduce-deployment-aws/          # AWS deployment configuration
└── README.md                      # This file
```

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Python 3.11+
- Node.js 18+ (for frontend)
- PostgreSQL 15+
- Redis 7+

### Local Development Setup

**1. Clone and navigate:**
```bash
cd C:\Users\raich\Desktop\hduce-monorepo
```

**2. Start all services:**
```bash
docker-compose up -d
```

**3. Verify services are running:**
```bash
docker-compose ps
```

**4. Access services:**
- Frontend: http://localhost
- API Documentation: http://localhost:8000/docs
- RabbitMQ Management: http://localhost:15672
- Grafana: http://localhost:3000

### Environment Variables
Critical environment variables (DO NOT MODIFY in production):

```env
# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres

# JWT Configuration (CRITICAL - NEVER CHANGE)
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
TOKEN_EXPIRY=24h

# Test User (Pre-configured)
TEST_USER_EMAIL=testuser@example.com
TEST_USER_PASSWORD=secret
```

## 🔧 Development Guidelines

### Code Structure
- **Python Code**: Follow FastAPI best practices with Pydantic models
- **Frontend**: React with TypeScript, functional components
- **Database**: PostgreSQL with SQLAlchemy ORM
- **API Documentation**: Auto-generated with OpenAPI/Swagger

### Shared Libraries
The `shared-libraries/` directory contains common Python modules used across all microservices:
- Database models and connection handling
- JWT authentication utilities
- Common schemas and validators

### Docker Configuration
Each service has two Dockerfiles:
- `Dockerfile`: For local development
- `Dockerfile.aws`: For AWS deployment (with specific optimizations)

## 📊 Production Data

### Current Data Statistics
- 37 medical appointments (real patient data)
- 11 system notifications
- 3 registered users including test user
- All data preserved in backup files

### Database Schemas
- **auth_db**: User authentication and JWT tokens
- **user_db**: User profiles and personal information
- **appointment_db**: Medical appointments and scheduling
- **notification_db**: System and user notifications

## 🚀 Deployment

### AWS Deployment Architecture
The platform is designed for deployment on AWS with 6 EC2 instances:

```
Instance 0: Bastion Host (SSH Gateway)
Instance 1: Databases (PostgreSQL, Redis, RabbitMQ)
Instance 2: Core Services (Auth, User, Appointment, Notification)
Instance 3: Frontend (NGINX + React)
Instance 4: Monitoring (Grafana, Prometheus, n8n)
Instance 5: IoT Services (MQTT Broker, MQTT Service, Metrics)
```

### Deployment Steps

**1. Infrastructure Setup:**
```bash
cd hduce-deployment-aws\terraform
terraform init
terraform plan
terraform apply
```

**2. Service Deployment:**
```powershell
.\deployment-scripts\Deploy-HDuce-AWS.ps1
```

**3. Backup Restoration:**
```powershell
.\deployment-scripts\Restore-Backup.ps1
```

## 🔐 Security

### Authentication & Authorization
- JWT-based authentication with HS256 algorithm
- Role-based access control (patient, doctor, admin)
- Password hashing with bcrypt
- Secure token management with refresh tokens

### Network Security
- Bastion host pattern for SSH access
- VPC-only communication for internal services
- Security groups with least-privilege access
- Encrypted database connections

### Secrets Management
- Environment variables for sensitive data
- Never commit secrets to version control
- Use AWS Secrets Manager for production

## 📈 Monitoring & Observability

### Built-in Monitoring
- Prometheus metrics collection
- Grafana dashboards for service health
- Application logging with structured JSON
- Health check endpoints on all services

### Key Metrics Tracked
- API response times and error rates
- Database connection pool status
- MQTT message throughput
- Service uptime and health status

## 🔄 CI/CD Pipeline

### Development Workflow
```
Local Development → Docker Build → AWS Deployment
```

### Version Control
- **Main branch**: Production-ready code
- **Feature branches**: New development
- **Pull requests** with code review required
- Automated testing before merge

## 🛠️ Troubleshooting

### Common Issues

**Docker Compose Fails:**
```bash
# Clean and rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

**Database Connection Issues:**
```bash
# Check PostgreSQL
docker exec hduce-postgres psql -U postgres -c "\l"
```

**Service Health Checks:**
```bash
# Check all services
curl http://localhost:8000/health
curl http://localhost:8001/health
```

### Logs Access
```bash
# View logs for specific service
docker-compose logs auth-service
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f auth-service
```

## 📚 API Documentation

Each microservice provides OpenAPI documentation:

| Service | Port | Documentation URL |
|---------|------|-------------------|
| Auth Service | 8000 | http://localhost:8000/docs |
| User Service | 8001 | http://localhost:8001/docs |
| Appointment Service | 8002 | http://localhost:8002/docs |
| Notification Service | 8003 | http://localhost:8003/docs |
| MQTT Service | 8004 | http://localhost:8004/docs |
| Metrics Service | 8005 | http://localhost:8005/docs |

## 🤝 Contributing

### Development Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation
4. Create pull request
5. Code review and approval
6. Merge to main

### Code Standards
- **Python**: PEP 8 compliance
- **TypeScript**: ESLint with strict rules
- **Commit messages**: Conventional commits
- **Documentation**: In-code docstrings + README updates

## 📄 License
This project is proprietary software. All rights reserved.

## 📞 Support
For technical support or questions:
1. Check existing documentation
2. Review API documentation
3. Contact development team

---

**Last Updated**: 2026-01-23  
**Version**: 1.0.0  
**Status**: Production Ready - AWS Deployment Configured