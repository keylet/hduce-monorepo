"""
Database utilities for HDUCE microservices.
"""

from sqlalchemy import text
from .postgres import (
    Base,
    DatabaseManager,
    get_db_session,
    get_db_engine,
    create_all_tables,
    TimestampMixin,
    SoftDeleteMixin
)

# --- CONNECTION FUNCTIONS ---
def init_db():
    """
    Compatibility function.
    Returns DatabaseManager (as in your old code).
    """
    return DatabaseManager


def check_db_connection(service_name: str = "appointments"):
    """Check database connection using SQLAlchemy 2.0"""
    try:
        from .postgres import DatabaseManager

        # List of services to try in order
        services_to_try = [service_name, "auth", "users", "notifications"]

        for svc in services_to_try:
            try:
                engine = DatabaseManager.get_engine(svc)
                if engine is None:
                    print(f"[WARNING] No engine for {svc}")
                    continue

                # USE text() for raw SQL in SQLAlchemy 2.0
                with engine.connect() as conn:
                    conn.execute(text("SELECT 1"))
                    conn.commit()  # Important in SQLAlchemy 2.0

                print(f"[SUCCESS] Connection successful to {svc}")
                return True
            except Exception as e:
                print(f"[FAILED] Connection to {svc}: {str(e)[:100]}")
                continue

        print("[ERROR] Could not connect to any database")
        return False

    except Exception as e:
        print(f"[ERROR] check_db_connection error: {e}")
        return False


def test_all_db_connections():
    """Test all available connections"""
    print("[TEST] Testing connections to all databases...")

    databases = ["auth", "users", "appointments", "notifications"]
    results = {}

    for db_name in databases:
        try:
            if check_db_connection(db_name):
                results[db_name] = "CONNECTED"
            else:
                results[db_name] = "FAILED"
        except Exception as e:
            results[db_name] = f"ERROR: {str(e)[:50]}"

    print("\n[SUMMARY] CONNECTION SUMMARY:")
    for db, status in results.items():
        print(f"  {db}: {status}")

    return results
# -------------------------------------

HAS_DATABASE_MODULE = True

__all__ = [
    "HAS_DATABASE_MODULE",
    "Base",
    "DatabaseManager",
    "get_db_session",
    "get_db_engine",
    "create_all_tables",
    "TimestampMixin",
    "SoftDeleteMixin",
    "init_db",
    "check_db_connection",
    "test_all_db_connections"
]
