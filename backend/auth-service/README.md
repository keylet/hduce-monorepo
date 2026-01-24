# Auth Service

## Overview
Authentication and authorization service handling user login, JWT token generation, and role-based access control.

## Service Information
- **Port**: 8000
- **Database**: auth_db (PostgreSQL)
- **Directory**: `backend/auth-service`

## API Endpoints

### POST /login
Authenticate user and generate JWT token.

```http
POST /login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "password"
}
```

### POST /register
Register a new user account.

```http
POST /register
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "password",
    "full_name": "John Doe",
    "role": "patient"
}
```

### POST /verify-token
Verify JWT token validity.

```http
POST /verify-token
Authorization: Bearer <jwt_token>
```

### GET /users/me
Get current authenticated user information.

```http
GET /users/me
Authorization: Bearer <jwt_token>
```

## Database Schema

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'patient',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- JWT tokens table (for refresh tokens)
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    token VARCHAR(512) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Dependencies
- None (independent service)

## Events
- **Produces**: user.registered, user.logged_in
- **Consumes**: None

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
TOKEN_EXPIRY=24h

# Service
PORT=8000
LOG_LEVEL=INFO
```

## Local Development

```bash
# Navigate to service directory
cd backend/auth-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8000
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
docker build -t auth-service .

# Run container
docker run -p 8000:8000 --env-file .env auth-service
```

## API Documentation
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information