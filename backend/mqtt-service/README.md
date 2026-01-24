# MQTT Service

## Overview
MQTT integration service for IoT medical devices, handling real-time data streaming and device management.

## Service Information
- **Port**: 8004
- **Database**: mqtt_db (PostgreSQL)
- **Directory**: `backend/mqtt-service`

## API Endpoints

### POST /devices/register
Register a new medical device.

```http
POST /devices/register
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "device_id": "device_123",
    "type": "blood_pressure_monitor",
    "patient_id": 1
}
```

### GET /devices/{device_id}/data
Get historical data from a device.

```http
GET /devices/{device_id}/data
Authorization: Bearer <jwt_token>
```

### POST /devices/{device_id}/command
Send command to a device.

```http
POST /devices/{device_id}/command
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "command": "start_monitoring",
    "parameters": {"interval": 30}
}
```

### WebSocket /ws/mqtt
WebSocket connection for real-time device data streaming.

```http
WS /ws/mqtt
WebSocket connection for real-time data
```

## Database Schema

```sql
-- Medical devices
CREATE TABLE medical_devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    patient_id INTEGER NOT NULL,
    type VARCHAR(100) NOT NULL,
    model VARCHAR(100),
    serial_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'inactive',
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Device readings
CREATE TABLE device_readings (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    metric_type VARCHAR(100) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);
```

## Dependencies
- Mosquitto MQTT Broker
- Database (for storing device data)

## Events
- **Produces**: device.data.received, device.connected, device.disconnected
- **Consumes**: MQTT topics: devices/+/data, devices/+/status

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mqtt_db

# Service
PORT=8004
LOG_LEVEL=INFO

# MQTT Broker
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=mqtt_user
MQTT_PASSWORD=mqtt_password
MQTT_CLIENT_ID=hduce_mqtt_service

# Topics
MQTT_TOPIC_DEVICES=devices/+/data
MQTT_TOPIC_STATUS=devices/+/status
MQTT_TOPIC_COMMANDS=devices/+/commands
```

## MQTT Topics Structure

### Device Data
```
devices/{device_id}/data
```
Payload example:
```json
{
    "device_id": "device_123",
    "metric_type": "blood_pressure",
    "systolic": 120,
    "diastolic": 80,
    "heart_rate": 72,
    "timestamp": "2024-01-23T10:30:00Z"
}
```

### Device Status
```
devices/{device_id}/status
```
Payload example:
```json
{
    "device_id": "device_123",
    "status": "online",
    "battery": 85,
    "signal_strength": -45
}
```

### Device Commands
```
devices/{device_id}/commands
```
Payload example:
```json
{
    "command": "start_monitoring",
    "interval": 30,
    "duration": 3600
}
```

## Local Development

```bash
# Navigate to service directory
cd backend/mqtt-service

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e ../../shared-libraries

# Run service
uvicorn main:app --reload --port 8004
```

## Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=src tests/

# Test MQTT connection
python scripts/test_mqtt_connection.py
```

## Docker

```bash
# Build image
docker build -t mqtt-service .

# Run container
docker run -p 8004:8004 --env-file .env mqtt-service
```

## API Documentation
- Swagger UI: http://localhost:8004/docs
- ReDoc: http://localhost:8004/redoc

## Health Check
- GET /health - Basic health status
- GET /health/detailed - Detailed health information

## Supported Device Types
- Blood Pressure Monitors
- Glucose Meters
- Pulse Oximeters
- ECG Monitors
- Weight Scales
- Temperature Sensors

## WebSocket Client Example

```javascript
const ws = new WebSocket('ws://localhost:8004/ws/mqtt');

ws.onopen = () => {
    console.log('Connected to MQTT service');
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Device data:', data);
};
```