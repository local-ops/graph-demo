# LightRAG + Ollama + Open WebUI (Kubernetes)

Kubernetes manifests plus a Taskfile workflow for **Colima Kubernetes** (profile `k3s`). **Ollama läuft nativ auf macOS** (Metal); im Cluster laufen nur **LightRAG** und **Open WebUI**, die den Host-Ollama über `host.lima.internal:11434` erreichen.

## Quickstart (macOS, Colima Profil `k3s`)

1. **Colima mit Kubernetes starten** (falls noch nicht geschehen):

   ```bash
   colima start -p k3s --kubernetes
   ```

2. **Ollama auf dem Mac installieren und starten** (Host-Dienst, Port 11434):

   - Download: https://ollama.com/download  
   - Prüfen: `curl -sS http://127.0.0.1:11434/api/tags`

3. **Repository vorbereiten**:

   ```bash
   task secrets:sync
   ```

   **`task secrets:sync` legt `deploy/lightrag.env` immer neu aus `deploy/lightrag.env.example` an.** Eine vorhandene Datei wird nach `deploy/.archived/lightrag.env.<Zeitstempel>` verschoben (Verzeichnis ist gitignored). Anschließend wird das Kubernetes-Secret gerendert.  
   `k8s/open-webui-secrets.yaml` wird weiterhin nur beim ersten `task k8s:apply` aus dem Example angelegt, falls sie fehlt — **Admin-Passwort und `webui-secret-key` dort setzen.**

4. **Modelle auf dem Host ziehen** (Metal, liest `LLM_MODEL` / `EMBEDDING_MODEL` aus `deploy/lightrag.env`):

   ```bash
   task models:pull
   ```

5. **Stack im Cluster ausrollen und warten**:

   ```bash
   task infra:start
   ```

6. **Port-Forward** (LightRAG + WebUI; Ollama bleibt auf `localhost:11434`):

   ```bash
   task port-forward
   ```

7. **Browser**: Open WebUI unter http://127.0.0.1:8080 (Login wie in `k8s/open-webui-secrets.yaml`). LightRAG-API: http://127.0.0.1:9621

**Hinweis Hostname:** Pods nutzen standardmäßig `http://host.lima.internal:11434` (Colima/Lima → macOS-Host). Falls Verbindungsfehler auftreten, in `deploy/lightrag.env` sowie in `k8s/open-webui.yaml` (`OLLAMA_BASE_URLS`) auf die in der [Colima-FAQ](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md) genannte Adresse wechseln (häufig `http://host.docker.internal:11434`) und erneut `task secrets:sync` sowie `task k8s:apply` ausführen.

**Upgrade von einer älteren Version** mit in-Cluster-Ollama: optional `kubectl --context=colima-k3s -n lightrag-stack delete deployment ollama pvc ollama-data --ignore-not-found=true`, damit keine alten Ressourcen herumliegen.

**Hinweis:** Jeder Lauf von `task secrets:sync` ersetzt `deploy/lightrag.env` durch die Vorlage; eigene Anpassungen vorher sichern oder aus `deploy/.archived/` zurückholen.

---

## Architektur (kurz)

| Komponente | Wo? | Zweck |
|------------|-----|--------|
| Ollama | macOS Host | LLM + Embeddings (Metal) |
| LightRAG | Pod im Cluster | RAG-API, spricht Ollama über `host.lima.internal` |
| Open WebUI | Pod im Cluster | UI; Ollama-URLs: Host-Ollama + LightRAG-Ollama-Emulation |

## Colima Profil `k3s`

Im `Taskfile` ist `CONTEXT` standardmäßig `colima-k3s`. Anderer Cluster:

```bash
task infra:start CONTEXT=your-context-name
```

## Voraussetzungen

- `kubectl` mit passendem Kontext
- `task` ([Taskfile](https://taskfile.dev/))
- **Ollama** als Host-Dienst auf dem Mac
- Default **StorageClass** für PVCs (LightRAG + Open WebUI)

## Einmalige Konfiguration

1. `task secrets:sync` — archiviert eine bestehende `deploy/lightrag.env`, kopiert dann immer frisch aus `deploy/lightrag.env.example`, rendert `k8s/generated/lightrag-env-secret.yaml`.
2. `k8s/open-webui-secrets.yaml` — wird bei erstem `task k8s:apply` aus dem Example kopiert; starke Werte für `webui-secret-key`, `webui-admin-email`, `webui-admin-password` setzen.

`k8s/open-webui-secrets.yaml` und `deploy/lightrag.env` sind gitignored.

## Deploy (nach Quickstart)

```bash
task models:pull
task infra:start
```

Modelle werden **nur noch auf dem Host** gezogen (`scripts/host-ollama-pull.sh`), nicht im Cluster.

## Alltag

```bash
task port-forward
```

- Open WebUI: http://127.0.0.1:8080  
- LightRAG: http://127.0.0.1:9621 (Ollama-kompatible Endpunkte für `lightrag:latest` laut LightRAG-Doku)

## Dokumente importieren

Mit laufendem Port-Forward:

```bash
task import:file FILE=./path/to/document.txt
```

## End-to-end Tests

```bash
task e2e:k8s
```

Erwartet **Host-Ollama** auf `http://127.0.0.1:11434`, port-forwarded LightRAG und WebUI. Upload von `e2e/fixtures/sample.txt`, Warten auf Indexierung, Smoke-Check per `POST /query`.

## Optional: anderer kube-Kontext

```bash
task infra:start CONTEXT=my-context
```

## Namespace löschen

```bash
task infra:stop
```

Löscht nur den Kubernetes-Namespace; **Ollama auf dem Host** und lokale Modelle unter `~/.ollama` bleiben unberührt.
