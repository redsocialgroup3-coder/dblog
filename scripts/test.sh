#!/usr/bin/env bash
# Script de testing para el monorepo dBLog.
# Ejecuta tests de API (pytest) y App (flutter test).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "  dBLog - Suite de Tests"
echo "========================================="

# -- API Tests --
echo ""
echo "-----------------------------------------"
echo "  API (FastAPI) - pytest"
echo "-----------------------------------------"
cd "$ROOT_DIR/dblog-api"

if [ -d "venv" ]; then
  source venv/bin/activate
fi

python -m pytest tests/ -v --tb=short
API_EXIT=$?

# -- App Tests --
echo ""
echo "-----------------------------------------"
echo "  App (Flutter) - flutter test"
echo "-----------------------------------------"
cd "$ROOT_DIR/dblog-app"
flutter test
APP_EXIT=$?

# -- Resumen --
echo ""
echo "========================================="
echo "  Resultados"
echo "========================================="

if [ $API_EXIT -eq 0 ]; then
  echo "  API:  PASSED"
else
  echo "  API:  FAILED"
fi

if [ $APP_EXIT -eq 0 ]; then
  echo "  App:  PASSED"
else
  echo "  App:  FAILED"
fi

echo "========================================="

exit $((API_EXIT + APP_EXIT))
