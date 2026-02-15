"""
PipelineX metrics overlay for FinSight API.

Imports the FinSight FastAPI app and instruments it with
prometheus-fastapi-instrumentator to expose /metrics endpoint.
"""

import sys
from pathlib import Path

# Ensure finsight source is on the path
finsight_root = Path("/app")
if str(finsight_root) not in sys.path:
    sys.path.insert(0, str(finsight_root))

from api.main import app  # noqa: E402
from prometheus_fastapi_instrumentator import Instrumentator  # noqa: E402

Instrumentator(
    should_group_status_codes=False,
    excluded_handlers=["/metrics"],
).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
