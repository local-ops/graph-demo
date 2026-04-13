#!/usr/bin/env bash
# Port-forward LightRAG and Open WebUI (always bash — avoids zsh trap quirks when invoked from Task).
set -euo pipefail

CONTEXT="${1:-}"
NAMESPACE="${2:-lightrag-stack}"

if [[ -n "$CONTEXT" ]]; then
  kubectl=(kubectl --context="$CONTEXT")
else
  kubectl=(kubectl)
fi

"${kubectl[@]}" -n "$NAMESPACE" port-forward svc/lightrag 9621:9621 &
PF_LIGHTRAG_PID=$!
"${kubectl[@]}" -n "$NAMESPACE" port-forward svc/open-webui 8080:8080 &
PF_WEBUI_PID=$!

cleanup() {
  kill "$PF_LIGHTRAG_PID" "$PF_WEBUI_PID" 2>/dev/null || true
}

trap cleanup INT TERM EXIT
wait
