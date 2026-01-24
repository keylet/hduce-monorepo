from setuptools import setup, find_packages

setup(
    name="hduce_shared",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "sqlalchemy>=2.0.0",
        "pydantic==2.5.0",           # Versión específica
        "pydantic-settings==2.1.0",  # Versión específica compatible
        "python-jose[cryptography]>=3.3.0",
        "passlib[bcrypt]>=1.7.4",
        "python-multipart>=0.0.6",
        "pika>=1.3.0",
        "psycopg2-binary>=2.9.0",
        "redis>=4.5.0",
    ],
)

