"""
base.py - Compatibility module for old imports.
New code should use: from hduce_shared.database import Base
"""
from .postgres import Base

__all__ = ["Base"]
