#!/usr/bin/env bash
# Legacy Kubernetes flow: background port-forwards, run e2e, cleanup.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT="${1:-}"
NAMESPACE="${2:-lightrag-stack}"

if [[ -n "$CONTEXT" ]]; then
  kubectl=(kubectl --context="$CONTEXT")
else
  kubectl=(kubectl)
fi

"${kubectl[@]}" -n "$NAMESPACE" port-forward svc/lightrag 9621:9621 >/tmp/lightrag_stack_pf_lightrag.log 2>&1 &
echo $! >/tmp/lightrag_stack_pf_lightrag.pid
"${kubectl[@]}" -n "$NAMESPACE" port-forward svc/open-webui 8080:8080 >/tmp/lightrag_stack_pf_webui.log 2>&1 &
echo $! >/tmp/lightrag_stack_pf_webui.pid

cleanup() {
  for f in /tmp/lightrag_stack_pf_lightrag.pid /tmp/lightrag_stack_pf_webui.pid; do
    if [[ -f "$f" ]]; then
      kill "$(cat "$f")" 2>/dev/null || true
      rm -f "$f"
    fi
  done
}

trap cleanup EXIT
sleep 2
bash "$ROOT_DIR/scripts/e2e.sh"
cleanup
trap - EXIT
