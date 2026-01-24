# Agregar esto al inicio de models.py si no está
from sqlalchemy.dialects.postgresql import ENUM

# Definir el ENUM para notification_type
notification_type_enum = ENUM(
    'EMAIL', 
    'SMS', 
    'APPOINTMENT_CREATED',
    'APPOINTMENT_UPDATED', 
    'APPOINTMENT_CANCELLED',
    'APPOINTMENT_REMINDER',
    name='notificationtype',
    create_type=False  # Ya existe en la BD
)
