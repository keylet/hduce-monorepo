# User Service

## Overview
User management service handling user profiles, personal information, and user data operations.

## Service Information
- **Port**: 8001
- **Database**: user_db (PostgreSQL)
- **Directory**: `backend/user-service`

## API Endpoints

### GET /users
Get list of all users (admin only).

```http
GET /users
Authorization: Bearer <jwt_token>
```

### GET /users/{user_id}
Get specific user by ID.

```http
GET /users/{user_id}
Authorization: Bearer <jwt_token>
```

### PUT /users/{user_id}
Update user information.

```http
PUT /users/{user_id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "full_name": "Updated Name",
    "phone": "+1234567890",
    "address": "123 Main St"
}
```

### GET /users/{user_id}/profile
Get complete user profile.

```http
GET /users/{user_id}/profile
Authorization: Bearer <jwt_token>
```

## Database Schema

```sql
-- User profiles
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    date_of_birth DATE,
    emergency_contact VARCHAR(255),
    medical_history TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User preferences
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_profiles(user_id),
    notification_preferences JSONB DEFAULT '{}',
    theme VARCHAR(50) DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en'
);
```

## Dependencies
- Auth Service (for user validation)

## Events
- **Produces**: user.profile.updated
- **Consumes**: user.registered

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/user_db

# Service
PORT=8001
LOG_LEVEL=INFO

# Auth Service URL
AUTH_SERVICE_URL=http://localhost:8000
```

## Local Development

```bash
# Navigate to service directory
cd backend/user-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8001
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
docker build -t user-service .

# Run container
docker run -p 8001:8001 --env-file .env user-service
```

## API Documentation
- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information