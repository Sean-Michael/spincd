from fastapi.testclient import TestClient

# Local imports
from ..main import app

client = TestClient(app)


def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "hello spincd!"}
