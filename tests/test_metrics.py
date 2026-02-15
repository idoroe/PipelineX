"""Tests for PipelineX metrics overlay."""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Add finsight to path so overlay can import it
finsight_root = Path(__file__).resolve().parent.parent / "finsight"
if str(finsight_root) not in sys.path:
    sys.path.insert(0, str(finsight_root))

from overlay.metrics import app  # noqa: E402

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
