#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/deploy/lightrag.env}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama CLI not found. Install Ollama on the Mac host: https://ollama.com/download" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE (copy from deploy/lightrag.env.example or run: task secrets:sync)" >&2
  exit 1
fi

read_var() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | head -n1 | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//' | tr -d '\r'
}

LLM_MODEL="$(read_var LLM_MODEL)"
EMBEDDING_MODEL="$(read_var EMBEDDING_MODEL)"

if [[ -z "$LLM_MODEL" || -z "$EMBEDDING_MODEL" ]]; then
  echo "Could not read LLM_MODEL or EMBEDDING_MODEL from $ENV_FILE" >&2
  exit 1
fi

echo "Pulling Ollama models on this machine (host): LLM=$LLM_MODEL embedding=$EMBEDDING_MODEL"
ollama pull "$LLM_MODEL"
ollama pull "$EMBEDDING_MODEL"
echo "Done."
