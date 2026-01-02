from fastapi.testclient import TestClient
from .main import app

client = TestClient(app)

def test_register_user():
    response = client.post("/register", json={"username": "testuser", "email": "testuser@example.com", "password": "testpassword"})
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_login_user():
    client.post("/register", json={"username": "testuser", "email": "testuser@example.com", "password": "testpassword"})
    response = client.post("/login", json={"username": "testuser", "password": "testpassword"})
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_invalid_login():
    response = client.post("/login", json={"username": "testuser", "password": "wrongpassword"})
    assert response.status_code == 401
