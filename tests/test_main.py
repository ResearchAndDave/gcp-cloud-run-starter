import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add parent directory to path to import main.py
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app # Assuming your FastAPI app instance is named 'app' in main.py

client = TestClient(app)

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    # Add more assertions if main.py's root path returns specific content
    # Based on current main.py, it returns {"Hello": "Cloud Run"}
    assert response.json() == {"Hello": "Cloud Run"}

def test_healthz():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
