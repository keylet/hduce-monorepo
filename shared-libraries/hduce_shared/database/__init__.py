"""
Database utilities for HDUCE microservices.
"""

from .postgres import (
    Base,
    DatabaseManager,
    get_db_session,
    get_db_engine,
    create_all_tables,
    TimestampMixin,
    SoftDeleteMixin
)

HAS_DATABASE_MODULE = True

__all__ = [
    "HAS_DATABASE_MODULE",
    "Base",
    "DatabaseManager",
    "get_db_session",
    "get_db_engine",
    "create_all_tables",
    "TimestampMixin",
    "SoftDeleteMixin"
]
