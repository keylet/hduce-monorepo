from setuptools import setup, find_packages

# Encontrar todos los paquetes
packages = find_packages()

print(f"Paquetes encontrados: {packages}")

setup(
    name="hduce-shared",
    version="1.0.0",
    author="HDUCE Team",
    description="Shared libraries for HDUCE microservices",
    packages=packages,
    python_requires=">=3.8",
    install_requires=[
        'PyJWT>=2.8.0',
        "fastapi>=0.104.0",
        "pydantic>=2.0.0",
        "python-jose[cryptography]>=3.3.0",
        "sqlalchemy>=2.0.0",
        "psycopg2-binary>=2.9.0",
        "pydantic-settings>=2.0.0",
    ],
)

