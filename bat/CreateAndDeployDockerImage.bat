@echo off

REM ===============================================
REM Script: CreateAndDeployDockerImage.bat
REM Description: Update the version tag, stop existing containers,
REM and start the new version using docker-compose.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

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

REM Connect to the remote server using SSH, navigate to the repository directory, and update the third line of the 'EnvFile' file with the new version tag.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteRepositoryPath% ; sed -i '3s/.*/DOCKER_IMAGE_TAG=%DockerImageTag%/' %EnvFile% 

REM It connects to the remote server via SSH, navigates to the repository directory, then takes down all services defined in 'docker-compose.yaml', removing orphaned containers.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath% && docker-compose -f %DockerComposeFile% --env-file=%EnvFile% down"

REM It connects to the remote server via SSH, navigates to the repository directory, and starts the services defined in 'docker-compose.yaml' in the background. It prints the status of the last executed command (usually 0 for success or 1 for failure).
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteRepositoryPath% && docker-compose -f %DockerComposeFile% --env-file=%EnvFile% up --build -d; echo \$?"