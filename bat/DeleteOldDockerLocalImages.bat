@echo off
REM ==============================================================================
REM Description: Normaliza fin de linea y ejecuta la limpieza de imagenes
REM   Docker locales en el servidor remoto (conserva las 3 mas recientes),
REM   con SSH endurecido y validacion temprana de argumentos.
REM Author: Pipeline_Jenkins_Angular_Docker maintainers
REM Usage: DeleteOldDockerLocalImages.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^>
REM Env Vars: ninguna (todo por argumentos).
REM Dependencies: ssh (OpenSSH); en remoto: bash, docker
REM Exit codes: 0 ok; 2 uso/argumentos invalidos.
REM ==============================================================================
setlocal EnableExtensions

if "%~1"=="" echo Usage: DeleteOldDockerLocalImages.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> 1>&2 & exit /b 2
if "%~2"=="" echo Usage: DeleteOldDockerLocalImages.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> 1>&2 & exit /b 2
if "%~3"=="" echo Usage: DeleteOldDockerLocalImages.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> 1>&2 & exit /b 2
if "%~4"=="" echo Usage: DeleteOldDockerLocalImages.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteRepositoryPath^> 1>&2 & exit /b 2

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteRepositoryPath=%4

REM ==============================
REM Script
REM ==============================

echo [%DATE% %TIME%] Cleaning old local Docker images on %SSHUser%@%SSHHost% (keep 3 most recent)
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath%/sh && sed -i 's/\r$//' deleteOldDockerLocalImages.sh && bash deleteOldDockerLocalImages.sh"
echo [%DATE% %TIME%] Remote cleanup finished.
