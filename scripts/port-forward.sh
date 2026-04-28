#!/usr/bin/env bash
# Compose runtime already exposes service ports on localhost.
set -euo pipefail

echo "No port-forward needed in Docker Compose mode."
echo "Open WebUI: http://127.0.0.1:8080"
echo "LightRAG:  http://127.0.0.1:9621"
