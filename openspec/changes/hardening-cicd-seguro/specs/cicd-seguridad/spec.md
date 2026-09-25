# Spec Delta

## Purpose

Define el comportamiento seguro del pipeline Jenkins: sin secretos en código, con parámetros declarados, opciones de robustez y gates de calidad y despliegue verificable. Cubre 50+ caracteres de propósito para validación estricta del contrato de seguridad CI/CD.

## ADDED Requirements

### Requirement: Sin secretos literales en Jenkinsfile

El pipeline SHALL obtener usuario SSH, host, clave privada e IPs vía `credentials()` y NUNCA contener literales `sa_jenkins`, `10.200.2.29`, rutas `C:\Users\...` ni `E:\Jenkins_Root\...` en `environment`.

#### Scenario: Escaneo de secretos limpio

- **WHEN** se ejecuta `grep -rEn "sa_jenkins|10\.200\.|C:\\\\Users|E:\\\\Jenkins" Jenkinsfile bat/ sh/ docker/` excluyendo documentación
- **THEN** el comando retorna exit 1 (sin coincidencias) y el Jenkinsfile contiene `credentials('ssh-remote-user')`, `credentials('ssh-remote-host')` y `sshUserPrivateKey(credentialsId: 'ssh-deploy-key', ...)`.

### Requirement: Parámetros y opciones declarativas

El pipeline SHALL declarar bloque `parameters { booleanParam('FORCE_PIPELINE', ...) }`, `options { timestamps(); timeout(time: 30, unit: 'MINUTES'); disableConcurrentBuilds(); buildDiscarder(logRotator(numToKeepStr: '20')) }` y usar `params.FORCE_PIPELINE` en los `when`.

#### Scenario: Pipeline parseable y con force run

- **WHEN** se inspecciona el Jenkinsfile
- **THEN** existe `parameters`, `options` con los 4 elementos y ningún stage referencia `params['Force pipeline execution']` legacy.

### Requirement: SSH seguro y comandos remotos con guarda

Todo `ssh`/`scp` SHALL usar `-o StrictHostKeyChecking=yes -o BatchMode=yes`, `scp` con clave vía variable de credentials y ningún `rm -rf $VAR/*` sin guarda `[ -n "$VAR" ] && [ "$VAR" != "/" ]`.

#### Scenario: Sin rm destructivo sin guarda

- **WHEN** se revisan `Jenkinsfile`, `bat/*`, `sh/*`
- **THEN** cada `rm -rf` está precedido de guarda de variable no vacía y distinta de `/`, y cada `ssh`/`scp` incluye las opciones StrictHostKeyChecking y BatchMode.

### Requirement: Gates de calidad y verificación post-deploy

El pipeline SHALL incluir stages `Lint`, `Test/Build` (cuando haya app) y `Verify Deploy` con `curl --fail` al `NGINX_HOST:NGINX_PORT/health` con reintentos, más `post { success, failure, always }` con `archiveArtifacts` y notificaciones (`emailext` o `echo` estructurado si no hay plugin).

#### Scenario: Deploy verificado o marcado fallido

- **WHEN** el deploy termina
- **THEN** el stage `Verify Deploy` ejecuta healthcheck con reintentos y si falla el build resulta `FAILURE` y se ejecuta rollback a la imagen previa.
