# Spec Delta

## Purpose

Define el esquema de versionado y trazabilidad de cada build: tags reproducibles con commit SHA, labels OCI en la imagen y artefacto build-info archivado para auditoría posterior del despliegue.

## ADDED Requirements

### Requirement: Tag SemVer más SHA

El sistema SHALL calcular `DOCKER_IMAGE_TAG = "1.${BUILD_NUMBER}-${GIT_SHORT_SHA}"` donde `GIT_SHORT_SHA` proviene de `checkout scm` (`env.GIT_COMMIT.take(7)`), y exportarlo al `.var` por clave (no por número de línea).

#### Scenario: Tag trazable generado

- **WHEN** corre un build del commit `abc1234` con `BUILD_NUMBER=42`
- **THEN** `DOCKER_IMAGE_TAG == "1.42-abc1234"` y `grep "^DOCKER_IMAGE_TAG=" docker/ANGULAR_APPLICATION.var` retorna esa línea.

### Requirement: Labels OCI en imagen

El `Dockerfile` SHALL incluir `LABEL org.opencontainers.image.revision`, `org.opencontainers.image.created`, `org.opencontainers.image.version` parametrizados por `ARG GIT_SHA / BUILD_TAG / BUILD_DATE`.

#### Scenario: Imagen inspeccionable

- **WHEN** se ejecuta `docker inspect <imagen> --format '{{.Config.Labels}}'`
- **THEN** los tres labels existen y `revision` coincide con el SHA del build.

### Requirement: Artefacto build-info archivado

El pipeline SHALL generar `build-info.json` con `{ commit, branch, build_tag, image, timestamp }` y archivarlo con `archiveArtifacts artifacts: 'build-info.json, docker/ANGULAR_APPLICATION.var'`.

#### Scenario: Auditoría posterior posible

- **WHEN** finaliza cualquier build (éxito o fallo)
- **THEN** `build-info.json` existe en el workspace y queda archivado como artefacto del build.
