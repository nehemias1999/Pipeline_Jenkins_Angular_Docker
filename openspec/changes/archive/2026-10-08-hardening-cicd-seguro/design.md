# Design

## Context

Agente Jenkins Windows (`SERVER_1`) + host Docker Linux vía SSH. Jenkinsfile actual mezcla rutas `C:\`/`E:\`, usa `.bat` con `xcopy`, `sed '3s/...'` y `docker-compose` v1. Dockerfile referencia `entrypoint.sh` inexistente y corre como root. Ver proposal.md para motivación.

## Goals / Non-Goals

**Goals:**

- Eliminar secretos del repo usando `credentials()` nativo Jenkins.
- Tags reproducibles + labels OCI + `build-info.json`.
- Scripts idempotentes con validación y logging.
- Compose v2 válido verificable con `docker compose config`.

**Non-Goals:**

- No migrar de Jenkins a GitHub Actions.
- No crear app Angular de ejemplo ni tests de frontend.
- No integrar Vault externo (solo IDs de credentials reservados).
- No aplicar infra real en verificación (solo lint/config/build seco).

## Decisions

- **credentials() + `sshagent` sobre variables env**: nativo, auditable en Jenkins; alternativa env-plano descartada por filtrarse en logs/artefactos.
- **Tag `1.BUILD_NUMBER-shortSHA`**: conserva prefijo `1.` existente, añade trazabilidad; alternativa SemVer puro pierde correlación commit.
- **Actualización `.var` por clave con `awk`/`sed ^KEY=`**: idempotente; alternativa `sed '3N'` descartada por frágil ante línea vacía inicial.
- **Conservar `.bat` endurecido + añadir `.ps1`/`.sh` espejo**: respeta agente Windows y permite migración gradual; alternativa reescribir todo a Groovy pierde reutilización fuera de Jenkins.
- **`nginx:1.27-alpine` + `USER appuser` + `HEALTHCHECK wget`**: `nginx:alpine` flotante no es reproducible; `curl` no existe en nginx:alpine, `wget` sí (busybox).
- **`restart: unless-stopped` + healthcheck + `deploy.resources.limits`**: evita `restart: always` que resucita contenedores en mantenimiento.

## Risks / Trade-offs

- [Credenciales faltantes en Jenkins] → `validate` falla temprano con mensaje que lista IDs requeridos; README documenta creación.
- [`dos2unix` ausente en nginx:alpine] → usar `busybox dos2unix` o eliminar conversión fijando `.gitattributes` + `COPY --chmod`.
- [`npm ci` sin app real en este repo] → stage Test/Build tolerante (`catchError`) hasta conectar repo Angular real.
- [SSH `StrictHostKeyChecking=yes` rompe primer run] → documentar `ssh-keyscan` previo en setup del agente.

## Migration Plan

1. Crear en Jenkins: `ssh-deploy-key` (SSH key), `ssh-remote-user`, `ssh-remote-host`, `remote-app-path` (opcional).
2. Mergear por requisito (6 PRs), cada uno con `openspec validate` + lint.
3. Primer run con `FORCE_PIPELINE=true` en rama test, verificar `build-info.json` y `docker compose config`.
4. Rollback: `docker compose --env-file` con tag previo (guardado en `PREV_TAG`), `docker image` previa conservada (retención 3).

## Open Questions

- Ninguna que cambie specs o tareas; plugin de mail (`emailext`) se detecta en runtime con fallback a `echo`.
