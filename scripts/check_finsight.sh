#!/usr/bin/env bash
set -euo pipefail

# Verify FinSight dependency is present and has expected structure
FINSIGHT_DIR="$(cd "$(dirname "$0")/.." && pwd)/finsight"

echo "=== FinSight Dependency Check ==="

if [ ! -d "$FINSIGHT_DIR" ]; then
    echo "ERROR: finsight/ directory not found."
    echo ""
    echo "Option A (preferred): Initialize the submodule:"
    echo "  git submodule update --init --recursive"
    echo ""
    echo "Option B (fallback): Clone FinSight manually:"
    echo "  git clone https://github.com/idoroe/Finsight-Lite.git finsight"
    exit 1
fi

MISSING=0

check_path() {
    if [ ! -e "$FINSIGHT_DIR/$1" ]; then
        echo "  MISSING: finsight/$1"
        MISSING=$((MISSING + 1))
    else
        echo "  OK:      finsight/$1"
    fi
}

echo ""
echo "Checking required files and directories..."
check_path "Dockerfile.api"
check_path "Dockerfile.frontend"
check_path "api/main.py"
check_path "api/routes.py"
check_path "frontend/package.json"
check_path "requirements.txt"
check_path "scripts/docker_entrypoint.sh"
check_path "tests/test_api.py"
check_path "ml"
check_path "dbt_project"
check_path "data/raw"

echo ""
if [ $MISSING -gt 0 ]; then
    echo "WARNING: $MISSING expected path(s) missing. FinSight may be incomplete."
    exit 1
else
    echo "All expected FinSight files present."
fi
