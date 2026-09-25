# Spec Delta

## Purpose

Define el comportamiento portable y seguro de los scripts de preparación, despliegue y limpieza: validan entradas, son idempotentes, registran con timestamps y actualizan versión por clave y no por posición.

## ADDED Requirements

### Requirement: Scripts validan entradas y son idempotentes

Cada script SHALL validar número de argumentos y variables no vacías al inicio (exit 2 con uso en caso contrario), usar `set -euo pipefail` (sh) / `$ErrorActionPreference='Stop'` (ps1) / `setlocal & if "%~1"=="" exit /b 2` (bat) y crear directorios con `-p` / `mkdir -Force` sin fallar si existen.

#### Scenario: Fallo temprano con uso

- **WHEN** se invoca cualquier script sin argumentos
- **THEN** exit code es 2 y stderr contiene `Usage:`.

### Requirement: Actualización de versión por clave

La actualización de `DOCKER_IMAGE_TAG` SHALL usar reemplazo por clave (`grep -q "^KEY=" || echo >> ; sed -i "s/^KEY=.*/KEY=.../"`) y NUNCA `sed '3s/.*/.../'` posicional.

#### Scenario: Cambio de tag sin corromper archivo

- **WHEN** se actualiza el tag dos veces seguidas con valores distintos
- **THEN** el `.var` contiene exactamente una línea `^DOCKER_IMAGE_TAG=` con el último valor y el resto de líneas intactas.

### Requirement: Logging trazable

Cada script SHALL prefijar líneas con timestamp ISO-8601 (`[2026-..] mensaje`) y hacer `echo` del tag/commit desplegado al final para correlación con `build-info.json`.

#### Scenario: Log correlacionable

- **WHEN** se ejecuta el flujo completo
- **THEN** cada línea de log matchea `^\[20[0-9]{2}-.*\]` y al menos una línea contiene el tag desplegado.
