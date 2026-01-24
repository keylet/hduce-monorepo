"""
RabbitMQ Utils usando Shared Libraries CORRECTAMENTE
"""
import json
import logging
import sys
from typing import Dict, Any

# Configurar logging
logger = logging.getLogger(__name__)

# Añadir path para shared-libraries
sys.path.insert(0, '/app')
sys.path.insert(0, '/app/shared-libraries')

try:
    from hduce_shared.rabbitmq import RabbitMQPublisher
    from hduce_shared.config import settings
    logger.info("✅ Shared libraries importadas desde /app")
except ImportError as e:
    logger.error(f"❌ Error importando shared libraries desde /app: {e}")
    # Intentar importar desde local para desarrollo
    try:
        sys.path.insert(0, '..')
        from shared_libraries.hduce_shared.rabbitmq import RabbitMQPublisher
        from shared_libraries.hduce_shared.config import settings
        logger.info("✅ Shared libraries importadas desde local")
    except ImportError as e2:
        logger.error(f"❌ Error importando shared libraries localmente: {e2}")
        raise


def publish_appointment_created(appointment_data: Dict[str, Any]) -> bool:
    """
    Publicar evento de cita creada usando RabbitMQPublisher de shared libraries
    """
    try:
        # Crear instancia del publisher
        publisher = RabbitMQPublisher()
        
        # Publicar el evento
        success = publisher.publish_appointment_created(appointment_data)
        
        if success:
            logger.info(f"✅ Evento APPOINTMENT_CREATED publicado: Cita {appointment_data.get('appointment_id', 'N/A')}")
        else:
            logger.error(f"❌ Falló al publicar evento APPOINTMENT_CREATED")
            
        return success
        
    except Exception as e:
        logger.error(f"❌ Error en publish_appointment_created: {e}")
        return False


# Alias para compatibilidad
publish_appointment_event = publish_appointment_created
