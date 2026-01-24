# Appointment Service

## Overview
Medical appointment scheduling service for patients and doctors, including availability management and appointment tracking.

## Service Information
- **Port**: 8002
- **Database**: appointment_db (PostgreSQL)
- **Directory**: `backend/appointment-service`

## API Endpoints

### GET /appointments
Get list of appointments.

```http
GET /appointments
Authorization: Bearer <jwt_token>
```

### POST /appointments
Create a new appointment.

```http
POST /appointments
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "patient_id": 1,
    "doctor_id": 2,
    "scheduled_time": "2024-01-25T10:00:00",
    "duration_minutes": 30,
    "reason": "Regular checkup"
}
```

### PUT /appointments/{appointment_id}/status
Update appointment status.

```http
PUT /appointments/{appointment_id}/status
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "status": "confirmed"
}
```

### GET /doctors/{doctor_id}/availability
Get doctor availability schedule.

```http
GET /doctors/{doctor_id}/availability
Authorization: Bearer <jwt_token>
```

## Database Schema

```sql
-- Appointments
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(50) DEFAULT 'scheduled',
    reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctor availability
CREATE TABLE doctor_availability (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER NOT NULL,
    day_of_week INTEGER, -- 0=Sunday, 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true
);
```

## Dependencies
- User Service (for patient/doctor information)
- Auth Service (for authentication)

## Events
- **Produces**: appointment.created, appointment.updated, appointment.cancelled
- **Consumes**: user.registered

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/appointment_db

# Service
PORT=8002
LOG_LEVEL=INFO

# Dependencies
AUTH_SERVICE_URL=http://localhost:8000
USER_SERVICE_URL=http://localhost:8001
```

## Local Development

```bash
# Navigate to service directory
cd backend/appointment-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8002
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
docker build -t appointment-service .

# Run container
docker run -p 8002:8002 --env-file .env appointment-service
```

## API Documentation
- Swagger UI: http://localhost:8002/docs
- ReDoc: http://localhost:8002/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information