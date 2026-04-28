---
name: go-change-rag
description: Guides safe changes for this graph-demo project to run a local LightRAG stack with Open WebUI and document ingestion. Use for any implementation, refactor, fix, or validation task in this repository, especially when LightRAG, Open WebUI, Kubernetes manifests, Taskfile tasks, scripts, document upload, or end-to-end checks are involved.
---

# go-change-rag

## Purpose

This project builds a local RAG setup with LightRAG, a web UI that can interact with LightRAG, and a simple path to add documents into the system.

## Default Rule

For this repository, apply this skill by default for all change tasks.

## Project Sources Of Truth

- `Taskfile.yml`
- `scripts/e2e.sh`
- `scripts/e2e-k8s.sh`
- `scripts/host-ollama-pull.sh`
- `k8s/open-webui.yaml`

Read these files first when behavior is unclear.

## Standard Operational Workflow

1. Understand impact area (`Taskfile.yml`, `scripts/`, `k8s/`, `deploy/`).
2. Implement the requested change with minimal scope.
3. Validate stack-facing behavior.
4. Run required checks and report concrete results.

## Preferred Commands

Use these commands as defaults unless the user asks otherwise:

- Start/update stack: `task infra:start`
- Pull host models: `task models:pull`
- Show local service URLs: `task infra:urls`
- Import document: `task import:file FILE=./path/to/file.txt`
- E2E checks (Compose default): `task e2e`
- E2E checks (compose bootstrap): `task e2e:compose`
- Legacy Kubernetes E2E: `task e2e:k8s`

## Current Runtime Baseline (Confirmed)

- Default runtime is Docker Compose, not k3s/Kubernetes.
- Ollama runs natively on the macOS host to use Metal acceleration.
- Containers must access host Ollama via `http://host.docker.internal:11434`.
- Host Ollama must be reachable beyond loopback; on macOS app installs use:
  - `launchctl setenv OLLAMA_HOST "0.0.0.0:11434"`
  - restart the Ollama app afterward.
- Validate host connectivity from containers explicitly when touching runtime wiring.

## Change Guardrails

- Keep changes aligned with local-first LightRAG + Open WebUI usage.
- Preserve easy document ingestion through LightRAG upload flow.
- Avoid unrelated refactors.
- Prefer explicit verification over assumptions.

## Mandatory Verification

After every substantial change, verify that the web UI path still works.

Minimum expectation:

1. Verify Open WebUI reachability.
2. Verify LightRAG health and query path.
3. Verify document upload/indexing flow.
4. Run `task e2e` or `task e2e:k8s` and capture outcomes.
5. For Compose/networking changes, verify container -> host Ollama path, e.g.:
   - `docker compose exec open-webui sh -lc 'wget -qO- http://host.docker.internal:11434/api/tags >/dev/null && echo ok'`

If verification cannot run, explain exactly why and provide the next executable command for the user.

## Mandatory Learning Loop After Successful Test

When verification succeeds, follow this sequence every time:

1. Produce a **Learning List** first.
   - Use concise bullets.
   - Include only project-relevant learnings discovered from the change/testing.
   - Separate confirmed facts from hypotheses.
2. Ask the user whether to incorporate those learnings into this skill.
3. Update skill files only after explicit user approval.

Use this question format:

`Should I integrate these learnings into .cursor/skills/go-change-rag now?`

## Suggested Output Format

Use this structure after successful tests:

```markdown
Learning List
- Confirmed: ...
- Confirmed: ...
- Hypothesis: ...

Would you like me to integrate these learnings into `.cursor/skills/go-change-rag` now?
```

## Additional Resources

- Detailed operational reference: [reference.md](reference.md)
