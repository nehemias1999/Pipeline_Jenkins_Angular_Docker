@echo off

REM ===============================================
REM Script: DeleteOldDockerLocalImages.bat
REM Description: Remove old local Docker images, keeping only the three 
REM most recent ones to optimize disk usage.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteRepositoryPath=%4

REM ==============================
REM Script
REM ==============================

ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteRepositoryPath%/sh ; sed -i 's/\r$//' deleteOldDockerLocalImages.sh; bash deleteOldDockerLocalImages.sh