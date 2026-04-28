# LightRAG + Ollama + Open WebUI (Docker Compose)

This project runs **LightRAG** and **Open WebUI** with Docker Compose.
**Ollama runs natively on macOS** to use Apple Metal performance, and containers call it via `host.docker.internal`.

## Quickstart (macOS + Docker Desktop)

1. **Install prerequisites**
   - Docker Desktop
   - [Task](https://taskfile.dev/)
   - Ollama: https://ollama.com/download

2. **Allow container access to host Ollama**

   Ollama listens on `127.0.0.1` by default. For container access, expose it on all interfaces:

   ```bash
   launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
   ```

   Then restart the Ollama app.

3. **Generate runtime env files**

   ```bash
   task secrets:sync
   ```

   This writes:
   - `deploy/lightrag.env` from `deploy/lightrag.env.example`
   - `deploy/open-webui.env` from `deploy/open-webui.env.example`

   Existing files are archived into `deploy/.archived/`.

4. **Adjust credentials and models**
   - Edit `deploy/open-webui.env` (`WEBUI_SECRET_KEY`, admin credentials)
   - Edit `deploy/lightrag.env` if you want different model names

5. **Pull models on the host (Metal)**

   ```bash
   task models:pull
   ```

6. **Start stack and wait for readiness**

   ```bash
   task infra:start
   ```

7. **Open services**
   - Open WebUI: http://127.0.0.1:8080
   - LightRAG API: http://127.0.0.1:9621
   - Host Ollama API: http://127.0.0.1:11434

## Architecture

- Ollama runs on the macOS host (`11434`)
- `lightrag` container calls host Ollama via:
  - `LLM_BINDING_HOST=http://host.docker.internal:11434`
  - `EMBEDDING_BINDING_HOST=http://host.docker.internal:11434`
- `open-webui` container uses:
  - host Ollama: `http://host.docker.internal:11434`
  - LightRAG endpoint on Compose network: `http://lightrag:9621`

## Daily workflow

```bash
task infra:start
task infra:urls
FILE="../../../Downloads/BGB.pdf" task import:file
task e2e
```

## Verification commands

```bash
docker compose ps
curl -fsS http://127.0.0.1:9621/health
curl -I http://127.0.0.1:8080/
task e2e
```

To verify host Ollama connectivity from inside a container:

```bash
docker compose exec open-webui sh -lc 'wget -qO- http://host.docker.internal:11434/api/tags >/dev/null && echo ok'
```

## Stop stack

```bash
task infra:stop
```

To also remove data volumes:

```bash
task infra:stop:volumes
```

## Legacy Kubernetes workflows

Kubernetes manifests are still available under `k8s/`.
Legacy tasks:
- `task legacy:k8s:secrets:sync`
- `task legacy:k8s:apply`
- `task e2e:k8s`
