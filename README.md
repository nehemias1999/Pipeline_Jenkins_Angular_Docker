# Jenkins Pipeline – Angular Application with Docker (hardened)

## Overview

CI/CD pipeline in Jenkins that builds, packages and deploys an Angular application
inside a Docker container on a remote host. Hardened per change
`hardening-cicd-seguro` (see `openspec/changes/archive/`): no secret literals,
declared parameters/options, strict SSH, Lint + Verify Deploy gates with rollback,
deterministic versioning (`1.BUILD-SHA`) and portable scripts (`.bat` + `ps1/` + `sh/` mirrors).

## Architecture Summary

1. Jenkins (agent `SERVER_1`, Windows) monitors the Git repository.
2. `Checking Changes` stops the build (`NOT_BUILT`) when there are no changes and
   `FORCE_PIPELINE` is false.
3. `Lint` validates scripts and compose config.
4. `Update Changes` → `Set content Docker image` → `Versionado y trazabilidad`
   (tag `1.BUILD_NUMBER-GIT_SHORT_SHA`, `build-info.json`, export of
   `DOCKER_IMAGE_TAG` into `docker/ANGULAR_APPLICATION.var` by key) →
   `Create and Deploy Docker image` → `Verify Deploy` (healthcheck
   `http://NGINX_HOST:NGINX_PORT/health` with retries; on failure the build is
   `FAILURE` and rolls back to the previous image).
5. `post { success, failure, always }` archives `build-info.json` and
   `docker/ANGULAR_APPLICATION.var` (`archiveArtifacts`, fingerprinted).

## Technologies Used

- Jenkins (declarative pipeline) – CI/CD orchestration
- Git – source control
- Angular + Node.js (Alpine) – build; Nginx (Alpine) – runtime
- Docker + Docker Compose – containerization and orchestration
- SSH (strict host checking, batch mode) – remote execution
- `credentials()` – secrets (never literals)

## Setup

### Jenkins credentials (manage in Jenkins, never in code)

- `ssh-remote-user` (Secret Text): remote SSH user.
- `ssh-remote-host` (Secret Text): remote Docker host.
- `ssh-deploy-key` (SSH Username with private key): deploy key; referenced as
  `sshUserPrivateKey(credentialsId: 'ssh-deploy-key', keyFileVariable: 'SSH_KEY_FILE', ...)`.

### Jenkins agent

- Windows agent labeled `SERVER_1` with `git`, `ssh`, `curl`, `docker` CLI and
  `docker compose` available; remote host with Docker Engine + SSH.

## Pipeline Parameters and Options

- `booleanParam('FORCE_PIPELINE', default false)`: run even without detected
  changes (used in `when` conditions).
- `options { timestamps(); timeout(time: 30, unit: 'MINUTES'); disableConcurrentBuilds(); buildDiscarder(logRotator(numToKeepStr: '20')) }`.

## Pipeline Stages

1. `Checking Changes` – git fetch + compare; `NOT_BUILT` when clean and not forced.
2. `Lint` – `bash -n sh/*.sh`, compose config check.
3. `Update Changes` – pull latest code.
4. `Set content Docker image` – prepare context, transfer to remote host.
5. `Versionado y trazabilidad` – tag `1.BUILD-SHA`, OCI labels, `build-info.json`,
   `.var` update by key (Groovy, Windows-safe).
6. `Create and Deploy Docker image` – build (pinned images, `appuser`, HEALTHCHECK),
   deploy via compose.
7. `Verify Deploy` – `curl --fail` healthcheck with retries; failure → `FAILURE` +
   rollback to the previous image.

## Security

- No literals (`sa_jenkins`, `10.200.x.x`, `C:\Users\...`, `E:\Jenkins...`) in
  `Jenkinsfile`/`bat/`/`sh/`/`docker/` (verified: security grep exits 1).
- Sample defaults in `docker/` use documentation IPs (`192.0.2.10`, RFC 5737).
- Every `ssh`/`scp` uses `-o StrictHostKeyChecking=yes -o BatchMode=yes`; every
  `rm -rf $VAR/*` is guarded (`[ -n "$VAR" ] && [ "$VAR" != "/" ]`).

## Rollback

- Automatic: `Verify Deploy` failure rolls back to the previous image.
- `bat/DeleteOldDockerLocalImages.bat` (and `ps1/`/`sh/` mirrors) prune old local
  images after a successful deploy.

## Verification (local, no Jenkins)

```bash
python3 tests/check_cicd_seguridad.py   # 4/4: security grep, params/options, SSH/guards, Lint+Verify
bash -n sh/*.sh && echo "sh OK"
docker compose -f docker/docker-compose.yaml config
```

## Project Structure

```
Pipeline_Jenkins_Angular_Docker/
├── Jenkinsfile
├── bat/                  # Windows automation (hardened, setlocal/quoting)
├── ps1/                  # PowerShell mirrors
├── sh/                   # POSIX mirrors (set -euo pipefail)
├── docker/               # Dockerfile (pinned, non-root, HEALTHCHECK), compose, .var, entrypoint.sh
├── tests/                # check_cicd_seguridad.py
├── openspec/             # specs (archived change hardening-cicd-seguro)
├── .yamllint.yml  .gitattributes
└── README.md
```

## Spec

- Change: `hardening-cicd-seguro` (archived) → `openspec/specs/`
  (`docker-hardening`, `scripts-portables`, `versionado-trazabilidad`, `cicd-seguridad`).
