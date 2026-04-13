# LightRAG + Ollama + Open WebUI (Kubernetes)

This repository ships a small Kubernetes manifest set plus a Taskfile workflow for Colima Kubernetes (or any kube context with default `StorageClass`).

## Colima profile `k3s`

The Taskfile defaults `CONTEXT` to `colima-k3s` (the usual `kubectl` context name for `colima start -p k3s --kubernetes`). Use another cluster with:

```bash
task infra:start CONTEXT=your-context-name
```

## Prerequisites

- `kubectl` configured for your cluster (`kubectl config get-contexts` should list your Colima context)
- `task` ([Taskfile](https://taskfile.dev/))
- Enough disk for model weights (PVCs are defined in `k8s/`)

## One-time configuration

1. Run `task secrets:sync` once: if `deploy/lightrag.env` is missing, it is created from `deploy/lightrag.env.example`. Edit that file to match your models and cluster before production use.
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

`task models:pull` runs a one-off Job that downloads the models configured in `k8s/ollama-pull-job.yaml`. Defaults follow common guidance for **Apple M4 + ~16 GB unified memory** (≈7–8B chat + `nomic-embed-text`); change `PULL_*` in that Job and `LLM_MODEL` / `EMBEDDING_*` in `deploy/lightrag.env` if you have more RAM or want a different stack.

If you already created `deploy/lightrag.env` from an older template, copy fresh defaults from `deploy/lightrag.env.example` or delete `deploy/lightrag.env` and run `task secrets:sync` again to regenerate it from the example.

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
