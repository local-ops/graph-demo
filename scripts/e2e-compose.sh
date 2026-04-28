#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$ROOT_DIR/deploy/lightrag.env" || ! -f "$ROOT_DIR/deploy/open-webui.env" ]]; then
  echo "Missing deploy env files. Run: task secrets:sync" >&2
  exit 1
fi

if command -v docker-compose >/dev/null 2>&1; then
  compose_cmd=(docker-compose)
else
  compose_cmd=(docker compose)
fi

"${compose_cmd[@]}" -f "$ROOT_DIR/docker-compose.yml" up -d
bash "$ROOT_DIR/scripts/e2e.sh"
