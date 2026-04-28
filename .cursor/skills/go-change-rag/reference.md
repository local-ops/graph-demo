# go-change-rag Reference

## Runtime Defaults

- Namespace: `lightrag-stack`
- LightRAG URL: `http://127.0.0.1:9621`
- Open WebUI URL: `http://127.0.0.1:8080`
- Ollama URL: `http://127.0.0.1:11434`

## Main Taskfile Commands

- `task infra:start`: sync secrets, apply workloads, wait for rollouts
- `task infra:wait`: wait for `lightrag` and `open-webui` deployments
- `task models:pull`: pull host-side `LLM_MODEL` and `EMBEDDING_MODEL`
- `task port-forward`: forwards LightRAG and Open WebUI to localhost
- `task import:file FILE=./doc.txt`: upload document to LightRAG
- `task e2e`: run checks with assumed connectivity
- `task e2e:k8s`: temporary port-forward + `task e2e`

## Relevant Endpoints

### LightRAG

- `GET /health`
- `POST /documents/upload` (multipart `file`)
- `GET /documents/track_status/{track_id}`
- `POST /query` (JSON body, e.g. `{"query":"...","mode":"naive"}`)

### Open WebUI

- `GET /` (reachability probe and base UI availability)

### Ollama

- `GET /api/tags`

## Verification Checklist

1. Services reachable (`/api/tags`, `/health`, `/`).
2. Document upload returns `track_id`.
3. Track status reaches `PROCESSED` and not `FAILED`.
4. Query response returns expected content.
5. Report pass/fail with exact command used.

## Troubleshooting

- **Open WebUI not reachable**
  - Run `task infra:wait`.
  - Check port-forward: `task port-forward`.
  - Confirm service exists in namespace.
- **Upload works but indexing stalls**
  - Poll `GET /documents/track_status/{track_id}`.
  - Check LightRAG logs and model availability.
- **Query quality is poor**
  - Ensure document finished processing.
  - Confirm correct model pulls with `task models:pull`.
- **E2E fails due to connectivity**
  - Use `task e2e:k8s` to enforce temporary port-forwards.
