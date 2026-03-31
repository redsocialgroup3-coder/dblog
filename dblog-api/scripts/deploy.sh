#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Pulling latest code..."
cd "$PROJECT_DIR"
git pull origin main

echo "==> Building Docker images..."
docker compose -f docker-compose.prod.yml build --no-cache

echo "==> Running database migrations..."
docker compose -f docker-compose.prod.yml run --rm api \
    alembic upgrade head

echo "==> Restarting services..."
docker compose -f docker-compose.prod.yml up -d

echo "==> Waiting for health check..."
sleep 5

HEALTH=$(curl -sf http://localhost:8000/health || echo "FAIL")
if echo "$HEALTH" | grep -q "ok\|healthy"; then
    echo "==> Deploy successful! API is healthy."
else
    echo "==> WARNING: Health check failed. Check logs with:"
    echo "    docker compose -f docker-compose.prod.yml logs api"
    exit 1
fi
