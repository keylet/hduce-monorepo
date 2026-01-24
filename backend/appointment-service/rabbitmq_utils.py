"""
RabbitMQ Utils usando Shared Libraries CORRECTAMENTE
"""
import json
import logging
import sys
from typing import Dict, Any


logger = logging.getLogger(__name__)


sys.path.insert(0, '/app')
sys.path.insert(0, '/app/shared-libraries')

try:
    from hduce_shared.rabbitmq import RabbitMQPublisher
    from hduce_shared.config import settings
    logger.info("✅ Shared libraries importadas desde /app")
except ImportError as e:
    logger.error(f"❌ Error importando shared libraries desde /app: {e}")
    
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
       
        publisher = RabbitMQPublisher()
        
      
        success = publisher.publish_appointment_created(appointment_data)
        
        if success:
            logger.info(f"✅ Evento APPOINTMENT_CREATED publicado: Cita {appointment_data.get('appointment_id', 'N/A')}")
        else:
            logger.error(f"❌ Falló al publicar evento APPOINTMENT_CREATED")
            
        return success
        
    except Exception as e:
        logger.error(f"❌ Error en publish_appointment_created: {e}")
        return False



publish_appointment_event = publish_appointment_created
