"""
PipelineX metrics overlay for FinSight API.

Imports the FinSight FastAPI app and instruments it with
prometheus-fastapi-instrumentator to expose /metrics endpoint.
"""

import sys
from pathlib import Path

# Ensure finsight source is on the path.
# In Docker: code lives under /app (finsight files copied directly).
# Outside Docker: finsight is a submodule at ./finsight relative to repo root.
_docker_root = Path("/app")
_repo_finsight = Path(__file__).resolve().parent.parent / "finsight"

for _p in [_docker_root, _repo_finsight]:
    if _p.is_dir() and str(_p) not in sys.path:
        sys.path.insert(0, str(_p))

from api.main import app  # noqa: E402
from prometheus_fastapi_instrumentator import Instrumentator  # noqa: E402

Instrumentator(
    should_group_status_codes=False,
    excluded_handlers=["/metrics"],
).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
