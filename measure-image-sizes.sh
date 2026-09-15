#!/usr/bin/env bash
# Builds the old single stage image and the new multi stage image and
# prints both sizes, so the before and after numbers are measured, not guessed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker build -q -f "$ROOT/server/Dockerfile.single-stage" -t skillswap-server:before "$ROOT/server" >/dev/null
docker build -q -f "$ROOT/server/Dockerfile" -t skillswap-server:after "$ROOT/server" >/dev/null

echo "Server image sizes:"
docker image ls skillswap-server --format "  {{.Tag}}\t{{.Size}}"
