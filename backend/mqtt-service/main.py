from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import paho.mqtt.client as mqtt
import json
from typing import Dict, List, Optional
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# In-memory storage for messages
message_store: Dict[str, List[Dict]] = {}

class MQTTManager:
    def __init__(self):
        self.client = None
        self.connected = False

    def connect(self):
        """Connect to MQTT broker"""
        try:
            self.client = mqtt.Client()
            self.client.on_connect = self.on_connect
            self.client.on_message = self.on_message

            # Connect to Mosquitto broker with timeout
            logger.info("Attempting to connect to MQTT broker: hduce-mosquitto:1883")
            self.client.connect("hduce-mosquitto", 1883, 60)
            self.client.loop_start()
            logger.info("MQTT client started")
        except Exception as e:
            logger.error(f"Failed to connect to MQTT broker: {e}")
            raise

    def on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        if rc == 0:
            self.connected = True
            logger.info("✅ Connected to MQTT broker successfully")

            # Subscribe to system topics
            self.subscribe("hduce/health/#")
            self.subscribe("hduce/metrics/#")
            self.subscribe("hduce/appointments/#")
            logger.info("✅ Subscribed to system topics")
        else:
            self.connected = False
            logger.error(f"❌ Failed to connect to MQTT broker with code: {rc}")

    def on_message(self, client, userdata, msg):
        """Callback when message is received"""
        try:
            topic = msg.topic
            payload = msg.payload.decode('utf-8')
            timestamp = datetime.now().isoformat()
            
            logger.info(f"📨 Message received on {topic}: {payload[:50]}...")
            
            # Store message
            if topic not in message_store:
                message_store[topic] = []
            
            message_store[topic].append({
                "payload": payload,
                "timestamp": timestamp,
                "qos": msg.qos
            })
            
            # Keep only last 100 messages per topic
            if len(message_store[topic]) > 100:
                message_store[topic] = message_store[topic][-100:]
                
        except Exception as e:
            logger.error(f"Error processing message: {e}")

    def publish(self, topic: str, payload: str, qos: int = 0):
        """Publish message to MQTT broker"""
        try:
            if not self.connected:
                logger.warning("Not connected to broker, attempting to reconnect...")
                self.connect()
                
            if not self.connected:
                raise Exception("Not connected to MQTT broker")
                
            logger.info(f"📤 Publishing to {topic}: {payload[:50]}... (QoS: {qos})")
            result = self.client.publish(topic, payload, qos=qos)
            
            # Wait for publish to complete
            if result.rc != mqtt.MQTT_ERR_SUCCESS:
                raise Exception(f"Publish failed with code: {result.rc}")
                
            logger.info(f"✅ Message published successfully (mid: {result.mid})")
            return result.mid
            
        except Exception as e:
            logger.error(f"❌ Error publishing message: {e}", exc_info=True)
            raise

    def subscribe(self, topic: str, qos: int = 0):
        """Subscribe to MQTT topic"""
        try:
            if self.connected and self.client:
                self.client.subscribe(topic, qos)
                logger.info(f"✅ Subscribed to {topic} (QoS: {qos})")
            else:
                logger.warning(f"Cannot subscribe, client not connected")
        except Exception as e:
            logger.error(f"Error subscribing to {topic}: {e}")

    def get_messages(self, topic: str, limit: int = 50) -> List[Dict]:
        """Get messages for a specific topic"""
        try:
            if topic in message_store:
                return message_store[topic][-limit:]
            return []
        except Exception as e:
            logger.error(f"Error getting messages for {topic}: {e}")
            return []

# Global MQTT manager
mqtt_manager = MQTTManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown events."""
    # Startup
    logger.info("🚀 MQTT Service starting up...")
    try:
        mqtt_manager.connect()
    except Exception as e:
        logger.error(f"Failed to start MQTT client: {e}")
    
    yield
    
    # Shutdown
    logger.info("🛑 MQTT Service shutting down...")
    if mqtt_manager.client:
        mqtt_manager.client.loop_stop()
        mqtt_manager.client.disconnect()

app = FastAPI(
    title="HDuce MQTT Service",
    description="MQTT messaging service for HDuce",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    status = "healthy" if mqtt_manager.connected else "unhealthy"
    return {
        "status": status,
        "service": "mqtt",
        "connected": mqtt_manager.connected,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/publish")
async def publish_message(
    topic: str = Query(..., description="MQTT topic to publish to"),
    payload: str = Query(..., description="Message payload"),
    qos: int = Query(0, ge=0, le=2, description="Quality of Service level (0, 1, 2)")
):
    """Publish message to MQTT broker"""
    try:
        message_id = mqtt_manager.publish(topic, payload, qos)
        return {
            "success": True,
            "message": "Message published successfully",
            "topic": topic,
            "message_id": message_id,
            "qos": qos,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"API Error publishing message: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to publish message: {str(e)}"
        )

@app.post("/subscribe")
async def subscribe_to_topic(
    topic: str = Query(..., description="MQTT topic to subscribe to"),
    qos: int = Query(0, ge=0, le=2, description="Quality of Service level")
):
    """Subscribe to MQTT topic"""
    try:
        mqtt_manager.subscribe(topic, qos)
        return {
            "success": True,
            "message": f"Subscribed to {topic}",
            "topic": topic,
            "qos": qos
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to subscribe: {str(e)}"
        )

@app.get("/messages/{topic}")
async def get_messages(
    topic: str,
    limit: int = Query(50, ge=1, le=100, description="Maximum number of messages to return")
):
    """Get messages for a specific topic"""
    try:
        messages = mqtt_manager.get_messages(topic, limit)
        return {
            "topic": topic,
            "count": len(messages),
            "messages": messages
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get messages: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8004,
        log_level="info"
    )
