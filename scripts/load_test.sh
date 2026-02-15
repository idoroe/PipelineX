#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# PipelineX — Load Test / Traffic Generator
# Sends sustained traffic to the FinSight API
# so Grafana dashboards have visible data.
# ──────────────────────────────────────────────

API_URL="http://localhost:8000"
DURATION=${1:-60}   # seconds, default 60
CONCURRENCY=${2:-5} # background workers, default 5

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}PipelineX — Load Test${NC}"
echo "  Duration:    ${DURATION}s"
echo "  Concurrency: ${CONCURRENCY} workers"
echo ""

# Verify API is up
if ! curl -sf "$API_URL/health" > /dev/null 2>&1; then
    echo -e "${YELLOW}API not reachable at $API_URL — is the stack running?${NC}"
    exit 1
fi
echo -e "${GREEN}API is healthy. Starting traffic...${NC}"
echo ""

ENDPOINTS=(
    "/health"
    "/api/stats"
    "/api/transactions?page=1&per_page=5"
    "/api/anomalies?page=1&per_page=5"
)

# Worker function
send_traffic() {
    local end_time=$(($(date +%s) + DURATION))
    while [ "$(date +%s)" -lt "$end_time" ]; do
        for ep in "${ENDPOINTS[@]}"; do
            curl -sf "${API_URL}${ep}" > /dev/null 2>&1 || true
        done
        sleep 0.2
    done
}

# Launch workers in background
PIDS=()
for i in $(seq 1 "$CONCURRENCY"); do
    send_traffic &
    PIDS+=($!)
done

echo "  Workers launched: ${#PIDS[@]}"
echo "  Press Ctrl+C to stop early."
echo ""

# Wait for all workers
for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

echo -e "${GREEN}Load test complete.${NC}"
echo "  Open Grafana at http://localhost:3001 to see the traffic."
