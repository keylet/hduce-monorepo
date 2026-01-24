import schemas
from datetime import datetime
import inspect

print("?? INSPECCI?N DEL ESQUEMA AppointmentCreate")
print("=" * 60)

# 1. Ver la definici?n de la clase
print("\n1. Definici?n de la clase:")
print(f"   schemas.AppointmentCreate: {schemas.AppointmentCreate}")

# 2. Ver los campos requeridos
print("\n2. Campos del esquema:")
appointment_fields = schemas.AppointmentCreate.__fields__
for field_name, field in appointment_fields.items():
    required = "REQUIRED" if field.required else "Optional"
    default = f"(default: {field.default})" if not field.required else ""
    print(f"   - {field_name}: {field.type_} - {required} {default}")

# 3. Ver el ejemplo de JSON Schema
print("\n3. JSON Schema:")
try:
    schema = schemas.AppointmentCreate.schema()
    print(f"   Title: {schema.get('title')}")
    print(f"   Required fields: {schema.get('required', [])}")
    
    print(f"   Properties:")
    for prop_name, prop_def in schema.get('properties', {}).items():
        prop_type = prop_def.get('type', 'unknown')
        print(f"     - {prop_name}: {prop_type}")
        
except Exception as e:
    print(f"   ? Error obteniendo schema: {e}")

print("\n" + "=" * 60)
