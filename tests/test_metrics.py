"""Tests for PipelineX metrics overlay."""

from fastapi.testclient import TestClient

from overlay.metrics import app

client = TestClient(app)


def test_health_via_instrumented_app():
    """Health endpoint still works through the metrics overlay."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_metrics_endpoint_exists():
    """The /metrics endpoint is exposed by the instrumentation overlay."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "python_info" in response.text
    assert "HELP" in response.text


def test_metrics_after_request():
    """After hitting an endpoint, /metrics reflects the request."""
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_request_duration_seconds" in response.text
