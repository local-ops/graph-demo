#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-lightrag-stack}"
LIGHTRAG_URL="${LIGHTRAG_URL:-http://127.0.0.1:9621}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
WEBUI_URL="${WEBUI_URL:-http://127.0.0.1:8080}"
E2E_SAMPLE="${E2E_SAMPLE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/e2e/fixtures/sample.txt}"
E2E_TRACK_TIMEOUT_SEC="${E2E_TRACK_TIMEOUT_SEC:-600}"
E2E_TRACK_POLL_SEC="${E2E_TRACK_POLL_SEC:-5}"

log() {
  printf "[%s] %s\n" "$(date -Iseconds)" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

http_ok() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -w "%{http_code}" "$url")"
  [[ "$code" == "200" || "$code" == "302" || "$code" == "307" ]]
}

wait_http() {
  local name="$1"
  local url="$2"
  local deadline=$((SECONDS + 300))
  while ((SECONDS < deadline)); do
    if http_ok "$url"; then
      log "$name is reachable: $url"
      return 0
    fi
    sleep 2
  done
  echo "Timeout waiting for $name ($url)" >&2
  return 1
}

json_get_track_id() {
  python3 - <<'PY'
import json, sys
data = json.load(sys.stdin)
print(data.get("track_id") or "")
PY
}

wait_track_processed() {
  local base="$1"
  local track_id="$2"
  local deadline=$((SECONDS + E2E_TRACK_TIMEOUT_SEC))

  while ((SECONDS < deadline)); do
    local body
    body="$(curl -fsS "$base/documents/track_status/$track_id")"
    if echo "$body" | python3 - <<'PY'
import json, sys

payload = json.load(sys.stdin)
docs = payload.get("documents") or []
if not docs:
    raise SystemExit(1)

statuses = {str(d.get("status", "")).upper() for d in docs}
if "FAILED" in statuses:
    print("FAILED")
    raise SystemExit(2)

if statuses and statuses <= {"PROCESSED"}:
    raise SystemExit(0)

raise SystemExit(1)
PY
    then
      log "Track $track_id finished successfully"
      return 0
    fi

    local rc="${PIPESTATUS[1]}"
    if [[ "$rc" == "2" ]]; then
      echo "Document processing failed for track_id=$track_id" >&2
      echo "$body" >&2
      return 1
    fi

    sleep "$E2E_TRACK_POLL_SEC"
  done

  echo "Timeout waiting for track_id=$track_id" >&2
  return 1
}

main() {
  require_cmd curl
  require_cmd python3

  log "Checking Ollama: $OLLAMA_URL"
  wait_http "Ollama" "$OLLAMA_URL/api/tags"
  curl -fsS "$OLLAMA_URL/api/tags" >/dev/null

  log "Checking LightRAG: $LIGHTRAG_URL"
  wait_http "LightRAG" "$LIGHTRAG_URL/health"
  curl -fsS "$LIGHTRAG_URL/health" >/dev/null

  log "Checking Open WebUI: $WEBUI_URL"
  wait_http "Open WebUI" "$WEBUI_URL/"

  if [[ ! -f "$E2E_SAMPLE" ]]; then
    echo "Missing sample file: $E2E_SAMPLE" >&2
    exit 1
  fi

  log "Uploading sample document"
  local upload_json
  upload_json="$(
    curl -fsS -X POST "$LIGHTRAG_URL/documents/upload" \
      -F "file=@${E2E_SAMPLE}"
  )"

  local track_id
  track_id="$(printf "%s" "$upload_json" | json_get_track_id)"
  if [[ -z "$track_id" ]]; then
    echo "Upload response missing track_id: $upload_json" >&2
    exit 1
  fi

  log "Waiting for indexing (track_id=$track_id)"
  wait_track_processed "$LIGHTRAG_URL" "$track_id"

  log "Smoke query via LightRAG /query API"
  local query_json
  query_json="$(
    curl -fsS "$LIGHTRAG_URL/query" \
      -H "Content-Type: application/json" \
      -d '{"query":"What city is mentioned in the E2E fixture?","mode":"naive"}'
  )"

  if ! printf "%s" "$query_json" | python3 - <<'PY'
import json, sys

payload = json.load(sys.stdin)
text = (payload.get("response") or "").lower()
if "springfield" not in text:
    raise SystemExit("Expected codeword city not found in response")
PY
  then
    echo "Unexpected /query response: $query_json" >&2
    exit 1
  fi

  log "E2E checks passed"
}

main "$@"
