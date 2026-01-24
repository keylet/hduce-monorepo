# Notification Service

## Overview
Notification service handling email, SMS, and push notifications for users and system alerts.

## Service Information
- **Port**: 8003
- **Database**: notification_db (PostgreSQL)
- **Directory**: `backend/notification-service`

## API Endpoints

### POST /notifications
Send a new notification.

```http
POST /notifications
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "user_id": 1,
    "type": "email",
    "title": "Appointment Reminder",
    "message": "Your appointment is tomorrow at 10:00 AM",
    "priority": "medium"
}
```

### GET /notifications/user/{user_id}
Get all notifications for a user.

```http
GET /notifications/user/{user_id}
Authorization: Bearer <jwt_token>
```

### PUT /notifications/{notification_id}/read
Mark notification as read.

```http
PUT /notifications/{notification_id}/read
Authorization: Bearer <jwt_token>
```

## Database Schema

```sql
-- Notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'push'
    title VARCHAR(255),
    message TEXT NOT NULL,
    priority VARCHAR(50) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'failed', 'read'
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification templates
CREATE TABLE notification_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    subject_template TEXT,
    body_template TEXT NOT NULL,
    variables JSONB DEFAULT '[]'
);
```

## Dependencies
- RabbitMQ (for async notifications)
- User Service (for user information)

## Events
- **Produces**: notification.sent, notification.failed
- **Consumes**: appointment.created, appointment.updated

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/notification_db

# Service
PORT=8003
LOG_LEVEL=INFO

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
RABBITMQ_QUEUE=notifications

# Email Configuration (if using email notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=noreply@hduce.com

# SMS Configuration (if using SMS)
SMS_PROVIDER=twilio
SMS_API_KEY=your-api-key
SMS_API_SECRET=your-api-secret
```

## Local Development

```bash
# Navigate to service directory
cd backend/notification-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8003
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
docker build -t notification-service .

# Run container
docker run -p 8003:8003 --env-file .env notification-service
```

## API Documentation
- Swagger UI: http://localhost:8003/docs
- ReDoc: http://localhost:8003/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information

## Notification Types

### Email
- Supports HTML templates
- Attachment support
- Template variables

### SMS
- Short message delivery
- Character limit: 160
- Unicode support

### Push Notifications
- Mobile app notifications
- Web push notifications
- Rich media support