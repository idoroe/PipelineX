#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# PipelineX — Failure Recovery Demo
# Demonstrates Docker self-healing: kill the API
# container and watch it automatically recover.
# ──────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:8000"
GRAFANA_URL="http://localhost:3001"
MAX_WAIT=60
POLL_INTERVAL=2

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PipelineX — Failure Recovery Demo      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Confirm API is healthy
echo -e "${YELLOW}[1/5] Checking API health...${NC}"
if curl -sf "$API_URL/health" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ API is healthy${NC}"
else
    echo -e "  ${RED}✗ API is not reachable at $API_URL${NC}"
    echo "  Make sure the stack is running: docker compose up -d"
    exit 1
fi
echo ""

# Step 2: Generate traffic so Grafana has data
echo -e "${YELLOW}[2/5] Generating traffic (20 requests)...${NC}"
for i in $(seq 1 20); do
    curl -sf "$API_URL/health" > /dev/null 2>&1 || true
    curl -sf "$API_URL/api/stats" > /dev/null 2>&1 || true
done
echo -e "  ${GREEN}✓ Sent 20 request pairs to /health and /api/stats${NC}"
echo ""

# Step 3: Kill the API process (triggers Docker restart policy)
echo -e "${YELLOW}[3/5] Crashing the API container...${NC}"
CONTAINER_NAME="pipelinex-api"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "  ${RED}✗ Could not find running API container.${NC}"
    echo "  Make sure the stack is running: docker compose up -d"
    exit 1
fi
# Kill PID 1 inside the container — this crashes the process and
# Docker's restart:always policy will automatically bring it back.
docker exec "$CONTAINER_NAME" python3 -c "import os,signal; os.kill(1, signal.SIGTERM)" 2>/dev/null || true
echo -e "  ${RED}✗ API process killed — container will restart automatically${NC}"
echo ""

# Step 4: Poll for recovery
echo -e "${YELLOW}[4/5] Polling for recovery (max ${MAX_WAIT}s)...${NC}"
ELAPSED=0
RECOVERED=false
while [ $ELAPSED -lt $MAX_WAIT ]; do
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
    if curl -sf "$API_URL/health" > /dev/null 2>&1; then
        RECOVERED=true
        echo -e "  ${GREEN}✓ API recovered after ~${ELAPSED}s${NC}"
        break
    else
        echo -e "  Attempt $((ELAPSED / POLL_INTERVAL)): ${RED}still down...${NC}"
    fi
done
echo ""

if [ "$RECOVERED" = true ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Recovery successful!                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   Recovery FAILED within ${MAX_WAIT}s            ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    exit 1
fi
echo ""

# Step 5: Point to Grafana
echo -e "${YELLOW}[5/5] Observe the incident in Grafana${NC}"
echo -e "  Open: ${BLUE}${GRAFANA_URL}${NC}"
echo -e "  Dashboard: ${BLUE}FinSight API - PipelineX${NC}"
echo ""
echo "  What you'll see:"
echo "  • Container Status panel dropped to DOWN (red)"
echo "  • Request Rate briefly flatlined"
echo "  • Both recovered automatically via Docker restart policy"
echo ""
echo -e "${GREEN}Demo complete.${NC}"
