#!/usr/bin/env bash
set -euo pipefail

echo "Starting local development environment..."
echo ""
echo "This will start:"
echo "  - Backend on http://localhost:8080"
echo "  - Gateway on http://localhost:3000"
echo ""

docker-compose up --build
