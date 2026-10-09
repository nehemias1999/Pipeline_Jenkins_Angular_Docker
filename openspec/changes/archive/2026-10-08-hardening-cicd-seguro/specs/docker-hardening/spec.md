# Spec Delta

## Purpose

Define el endurecimiento de los artefactos Docker para builds reproducibles, mínimos y ejecutados sin privilegios, con verificación de salud y configuración de compose válida en spec v2.

## ADDED Requirements

### Requirement: Dockerfile reproducible y no-root

El `Dockerfile` SHALL pinear `node:22.18-alpine` y `nginx:1.27-alpine`, copiar un `entrypoint.sh` existente o eliminar su referencia, incluir `HEALTHCHECK --interval=30s CMD wget -qO- http://localhost/ || exit 1`, crear usuario `appuser` y terminar con `USER appuser`, más `.dockerignore` que excluya `.git`, `node_modules`, `deploy`.

#### Scenario: Build y runtime verificados

- **WHEN** se ejecuta `docker build` y `docker run --user appuser`
- **THEN** el build termina sin error por `entrypoint.sh` faltante, `docker inspect` muestra `User == "appuser"` y `Healthcheck` definido.

### Requirement: Compose v2 válido y observable

El `docker-compose.yaml` SHALL omitir `version` obsoleto, usar `env_file: [ANGULAR_APPLICATION.var]`, `restart: unless-stopped`, `healthcheck` en servicio `web`, `deploy.resources.limits` y `pull_policy: build`.

#### Scenario: Config válida

- **WHEN** se ejecuta `docker compose config`
- **THEN** retorna exit 0, el servicio `web` resuelve `image` con tag del `.var` y contiene `healthcheck` y `restart: unless-stopped`.
