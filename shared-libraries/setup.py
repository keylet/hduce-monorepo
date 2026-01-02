from setuptools import setup

setup(
    name="hduce-shared-libs",
    version="0.1.0",
    packages=["hduce_shared_libs"],
    package_dir={
        "hduce_shared_libs": "."
    },
    install_requires=[
        "pydantic>=2.0.0",
        "PyJWT>=2.0.0",
        "python-dotenv>=1.0.0",
        "email-validator>=2.0.0",  # <- AGREGADO
    ],
    python_requires=">=3.8",
)
