# Proposal

## Why

El pipeline Jenkins actual despliega una app Angular con Docker pero presenta riesgos de seguridad (secretos en texto plano, SSH sin validación, contenedor como root), nula trazabilidad (tags sin SHA, sin labels OCI, sin provenance) y fragilidad operativa (sed por número de línea, `rm -rf` sin validación, `env_file` incorrecto, `entrypoint.sh` inexistente, compose v1 obsoleto). Endurecerlo ahora evita filtración de credenciales, despliegues no reproducibles y caídas silenciosas.

## What Changes

- Jenkinsfile declarativo portable: bloque `parameters`, `options` (timestamps, timeout, disableConcurrentBuilds, buildDiscarder), `credentials()` para SSH user/host/key e IPs, `environment` sin secretos literales, validación de cambios vía `checkout scm` + `git diff`, stages de lint/test/build/scan, verificación post-deploy con healthcheck y rollback, notificaciones.
- Versionado `1.<BUILD_NUMBER>-<shortSHA>` + `DOCKER_IMAGE_TAG` derivado, labels OCI (`org.opencontainers.image.*`) en Dockerfile y `build-info.json` con commit, branch, build, fecha como artefacto archivado.
- Dockerfile multi-stage endurecido: versiones pineadas (`node:22.18-alpine`, `nginx:1.27-alpine`), usuario no-root, `HEALTHCHECK`, corrección/creación de `entrypoint.sh` o eliminación de su copia, `.dockerignore`, `npm ci --audit` y `npm run build -- --configuration production`.
- `docker-compose.yaml` a spec v2 (sin `version`), `env_file` corregido a `ANGULAR_APPLICATION.var`, healthcheck, `restart: unless-stopped`, límites de recursos, `pull_policy: build`.
- Scripts portables y seguros: validación de argumentos, `set -euo pipefail` / `$ErrorActionPreference='Stop'`, SSH con `StrictHostKeyChecking + BatchMode`, reemplazo de `sed '3s/...'` por actualización clave=valor idempotente, `rm -rf` con guarda de variable no vacía, logging con timestamps para trazabilidad.
- Calidad/gates: `yamllint`, `shellcheck`, `hadolint` (si disponible), `bash -n`, `npm test`/`npm run build` cuando haya app, `docker build` de verificación, `docker compose config` como validación, sin aplicar infra real en verificación.

## Capabilities

### New Capabilities

- `cicd-seguridad`: Jenkinsfile sin secretos literales, SSH seguro, gates de calidad y post con healthcheck/rollback/notificaciones.
- `versionado-trazabilidad`: esquema de tags SemVer+SHA, labels OCI y artefacto build-info archivados por build.
- `docker-hardening`: Dockerfile y compose endurecidos, reproducibles y verificables.
- `scripts-portables`: scripts .bat/.ps1/.sh validados, idempotentes y con logging trazable.

### Modified Capabilities

- Ninguna (repo sin specs previas).

## Impact

- Afecta: `Jenkinsfile`, `docker/Dockerfile`, `docker/docker-compose.yaml`, `docker/ANGULAR_APPLICATION.var`, `bat/*.bat`, `sh/*.sh`, nuevo `docker/.dockerignore`, `docker/entrypoint.sh` (crear o eliminar referencia), `docker/build-info.json` (generado), `.yamllint.yml`, `README.md`.
- Sistemas: agente Jenkins `SERVER_1` (Windows) + host Docker remoto Linux vía SSH; requiere credentials `ssh-deploy-key`, `ssh-remote-user`, `ssh-remote-host` creadas en Jenkins. **BREAKING**: el pipeline exigirá esas credentials y fallará si no existen; el tag deja de ser `1.BUILD_ID` puro.
