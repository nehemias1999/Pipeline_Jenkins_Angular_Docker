@echo off
REM ==============================================================================
REM Description: Actualiza el tag DOCKER_IMAGE_TAG por clave (awk, nunca por
REM   posicion de linea) en el .var remoto, detiene los contenedores y levanta
REM   la nueva version con docker compose, con SSH endurecido.
REM Author: Pipeline_Jenkins_Angular_Docker maintainers
REM Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^>
REM Env Vars: ninguna (todo por argumentos).
REM Dependencies: ssh (OpenSSH); en remoto: awk, grep, docker compose
REM Exit codes: 0 ok; 2 uso/argumentos invalidos.
REM ==============================================================================
setlocal EnableExtensions

if "%~1"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~2"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~3"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~4"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~5"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~6"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2
if "%~7"=="" echo Usage: CreateAndDeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> ^<DockerImageTag^> ^<EnvFile^> ^<DockerComposeFile^> 1>&2 & exit /b 2

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteRepositoryPath=%4
SET DockerImageTag=%5
SET EnvFile=%6
SET DockerComposeFile=%7

REM ==============================
REM Script
REM ==============================

echo [%DATE% %TIME%] Updating DOCKER_IMAGE_TAG=%DockerImageTag% in %EnvFile% (by key)
REM Updates DOCKER_IMAGE_TAG by key with awk (idempotent); never by line position.
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath% && awk -v k=DOCKER_IMAGE_TAG -v v='%DockerImageTag%' 'BEGIN{FS=OFS=\"=\"} $1==k{$2=v;f=1}{print} END{if(!f)print k\"=\"v}' %EnvFile% > %EnvFile%.tmp && mv %EnvFile%.tmp %EnvFile% && grep '^DOCKER_IMAGE_TAG=' %EnvFile%"

echo [%DATE% %TIME%] Stopping services with %DockerComposeFile%
REM Takes down all services defined in the compose file, removing orphaned containers.
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath% && docker compose -f %DockerComposeFile% --env-file=%EnvFile% down"

echo [%DATE% %TIME%] Starting services with %DockerComposeFile%
REM Starts the services in the background and prints the exit status.
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath% && docker compose -f %DockerComposeFile% --env-file=%EnvFile% up --build -d; echo $?"

echo [%DATE% %TIME%] Deployed tag: %DockerImageTag%
