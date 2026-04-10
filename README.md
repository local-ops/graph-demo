# LightRAG + Ollama + Open WebUI (Kubernetes)

This repository ships a small Kubernetes manifest set plus a Taskfile workflow for Colima Kubernetes (or any kube context with default `StorageClass`).

## Prerequisites

- `kubectl` configured for your cluster (`colima kubectl` context is fine)
- `task` ([Taskfile](https://taskfile.dev/))
- Enough disk for model weights (PVCs are defined in `k8s/`)

## One-time configuration

1. Copy `deploy/lightrag.env.example` to `deploy/lightrag.env` and adjust models if needed.
2. Copy `k8s/open-webui-secrets.example.yaml` to `k8s/open-webui-secrets.yaml` and set strong values for:
   - `webui-secret-key`
   - `webui-admin-email`
   - `webui-admin-password`

`k8s/open-webui-secrets.yaml` and `deploy/lightrag.env` are gitignored.

## Deploy

```bash
task infra:start
task models:pull
```

`task models:pull` runs a one-off Job that downloads the models configured in `k8s/ollama-pull-job.yaml` (defaults are sized for CPU-only setups).

## Day-to-day usage

```bash
task port-forward
```

Then open Open WebUI at `http://127.0.0.1:8080` and sign in with the admin credentials from `k8s/open-webui-secrets.yaml`.

LightRAG is available at `http://127.0.0.1:9621` and exposes an Ollama-compatible API on the same port. Open WebUI is preconfigured with two Ollama connections:

- Direct Ollama for normal chat models
- LightRAG for the `lightrag:latest` model (per upstream docs)

## Import documents

With port-forwarding active:

```bash
task import:file FILE=./path/to/document.txt
```

## End-to-end tests

```bash
task e2e:k8s
```

This starts temporary port-forwards, waits for health endpoints, uploads `e2e/fixtures/sample.txt`, waits for indexing, and asserts a `/query` smoke response.

## Optional: non-default kube context

```bash
task infra:start CONTEXT=my-context
```
