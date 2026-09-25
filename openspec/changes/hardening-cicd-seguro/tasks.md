# Tasks

## 1. Base y validación

- [ ] 1.1 Crear `.yamllint.yml`, `.dockerignore`, `.gitattributes` y verificar `yamllint docker/docker-compose.yaml` exit 0
- [ ] 1.2 Crear `docker/entrypoint.sh` mínimo (o eliminar su COPY) y verificar `docker build` falla/succeed según decisión y `bash -n sh/*.sh` exit 0

## 2. REQ Seguridad Jenkinsfile (cicd-seguridad)

- [ ] 2.1 Migrar Jenkinsfile a parameters/options/credentials + SSH con StrictHostKeyChecking/BatchMode y verificar `grep -rEn "sa_jenkins|10\.200\.|C:\\\\Users" Jenkinsfile` exit 1
- [ ] 2.2 Añadir stages Lint + Verify Deploy con healthcheck/rollback + post archiveArtifacts y verificar groove parseable (paréntesis balanceados) y `when` usa `params.FORCE_PIPELINE`

## 3. REQ Versionado (versionado-trazabilidad)

- [ ] 3.1 Implementar tag `1.BUILD-SHA`, labels OCI ARG y `build-info.json` y verificar `grep "^DOCKER_IMAGE_TAG=1\."` y `jq . build-info.json` exit 0

## 4. REQ Docker (docker-hardening)

- [ ] 4.1 Pinear imágenes, USER appuser, HEALTHCHECK, compose v2 con healthcheck/limits/env_file corregido y verificar `docker compose config` exit 0

## 5. REQ Scripts (scripts-portables)

- [ ] 5.1 Endurecer `bat/*.bat` + espejos `ps1`/`sh` (validación args exit 2, guarda rm-rf, update por clave, logging timestamp) y verificar invocación sin args exit 2 y doble update deja una sola línea `^DOCKER_IMAGE_TAG=`

## 6. Integración y docs

- [ ] 6.1 Actualizar README (setup credentials, rollback, verificación) y verificar `openspec validate --strict` exit 0
