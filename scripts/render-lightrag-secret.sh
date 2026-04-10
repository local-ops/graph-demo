#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/deploy/lightrag.env}"
OUT_FILE="${2:-$ROOT_DIR/k8s/generated/lightrag-env-secret.yaml}"
NAMESPACE="${NAMESPACE:-lightrag-stack}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  echo "Copy deploy/lightrag.env.example to deploy/lightrag.env and edit it." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"

kubectl create secret generic lightrag-env \
  --namespace="$NAMESPACE" \
  --from-env-file="$ENV_FILE" \
  --dry-run=client \
  -o yaml >"$OUT_FILE"

echo "Wrote $OUT_FILE"
