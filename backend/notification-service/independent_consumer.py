import sys
import os

# Añadir shared-libraries al path
sys.path.insert(0, '/app/shared-libraries')
sys.path.insert(0, '/app')

import json
import logging
from datetime import datetime
from typing import Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import text

# Import desde shared-libraries - CORREGIDO
from hduce_shared.database import DatabaseManager
from hduce_shared.rabbitmq.consumer import RabbitMQConsumer
from hduce_shared.rabbitmq.config import RabbitMQConfig
from hduce_shared import get_settings

# Import local desde database.py (SESSIONLOCAL YA CONFIGURADO)
from database import SessionLocal
from models import Notification

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class NotificationConsumer:
    def __init__(self):
        self.settings = get_settings()
        self.rabbitmq_config = RabbitMQConfig()
        # NO crear sesión aquí - se creará en cada mensaje
        self.db_session = None  # Se creará dinámicamente

    def get_doctor_name(self, doctor_id: int) -> str:
        """Obtiene el nombre del doctor desde appointment_db"""
        try:
            logger.info(f"🔍 Buscando doctor_id: {doctor_id}")

            # Obtener engine para appointments database
            engine = DatabaseManager.get_engine("appointments")

            if engine is None:
                logger.error("❌ No se pudo obtener engine para appointments database")
                return f"Doctor {doctor_id}"

            # Consultar nombre del doctor
            with engine.connect() as conn:
                result = conn.execute(
                    text("SELECT name FROM doctors WHERE id = :doctor_id"),
                    {"doctor_id": doctor_id}
                ).fetchone()

                if result:
                    doctor_name = result[0]
                    logger.info(f"✅ Doctor encontrado: {doctor_name}")
                    return doctor_name
                else:
                    logger.warning(f"⚠️ Doctor con ID {doctor_id} no encontrado")
                    return f"Doctor {doctor_id}"

        except Exception as e:
            logger.error(f"❌ Error al obtener doctor: {e}")
            return f"Doctor {doctor_id}"

    def process_message(self, message: Dict[str, Any]) -> None:
        """Procesa mensajes de RabbitMQ"""
        try:
            logger.info(f"📨 Mensaje recibido: {message}")

            # Extraer datos del mensaje
            event_type = message.get('event_type', '')
            data = message.get('data', {})

            if event_type.upper() == "APPOINTMENT_CREATED":
                # OBTENER NOMBRE DEL DOCTOR
                doctor_id = data.get('doctor_id')
                doctor_name = self.get_doctor_name(doctor_id) if doctor_id else "Doctor"

                # Crear sesión de base de datos
                db = SessionLocal()
                try:
                    notification = Notification(
                        user_id=data.get('patient_id'),
                        user_email=data.get('patient_email', ''),
                        title=f"Cita médica programada con Dr. {doctor_name}",
                        message=(
                            f"Tu cita con el Dr. {doctor_name} "
                            f"ha sido programada para el {data.get('appointment_date')} "
                            f"a las {data.get('appointment_time')}. "
                            f"Motivo: {data.get('reason', 'Consulta médica')}"
                        ),
                        notification_type="appointment",
                        is_read=False,
                        created_at=datetime.utcnow()
                    )

                    db.add(notification)
                    db.commit()
                    logger.info(f"✅ Notificación creada para usuario {data.get('patient_id')} - Cita #{data.get('appointment_id')}")
                    logger.info(f"📝 Detalles: Título='{notification.title}'")

                except Exception as e:
                    db.rollback()
                    logger.error(f"❌ Error al crear notificación: {e}")
                    logger.error(f"🔍 Datos del mensaje: {data}")
                finally:
                    db.close()  # Cerrar sesión siempre
            else:
                logger.warning(f"⚠️ Evento no manejado: {event_type}")

        except Exception as e:
            logger.error(f"❌ Error procesando mensaje: {e}")

    def start_consuming(self) -> None:
        """Inicia el consumidor de RabbitMQ"""
        try:
            consumer = RabbitMQConsumer()
            logger.info("🎯 Iniciando consumidor de RabbitMQ...")
            logger.info(f"✅ Configuración: Exchange={self.rabbitmq_config.appointment_exchange}, Queue={self.rabbitmq_config.appointment_queue}, RoutingKey={self.rabbitmq_config.appointment_routing_key}")
            consumer.start_consuming(callback=self.process_message)
        except Exception as e:
            logger.error(f"❌ Error en el consumidor: {e}")
            raise

def start_consumer():
    """Inicia el consumidor de RabbitMQ (para importación desde main.py)"""
    try:
        notification_consumer = NotificationConsumer()
        notification_consumer.start_consuming()
    except Exception as e:
        logger.error(f"❌ Error en start_consumer: {e}")
        raise

# SOLO ejecutar si se llama directamente
if __name__ == "__main__":
    print("🚀 Iniciando Notification Consumer de forma independiente...")
    start_consumer()
