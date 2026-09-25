# ==============================================================================
# Description: Actualiza el tag DOCKER_IMAGE_TAG por clave (awk, nunca por
#   posicion de linea) en el .var remoto, detiene los contenedores y levanta
#   la nueva version con docker compose, con SSH endurecido.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: .\CreateAndDeployDockerImage.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p> -DockerImageTag <t> -EnvFile <f> -DockerComposeFile <f>
# Env Vars: ninguna requerida (todo por parametros).
# Dependencies: PowerShell 5.1+, ssh (OpenSSH); en remoto: awk, grep, docker compose
# Exit codes: 0 ok; 2 uso/argumentos invalidos; 1 error operativo.
# ==============================================================================

$ErrorActionPreference = 'Stop'

param(
  [string]$SSHPrivateKeyPath = '',
  [string]$SSHUser = '',
  [string]$SSHHost = '',
  [string]$RemoteRepositoryPath = '',
  [string]$DockerImageTag = '',
  [string]$EnvFile = '',
  [string]$DockerComposeFile = ''
)

# Write-Log: imprime un mensaje con timestamp ISO-8601 UTC.
function Write-Log {
  param([string]$Message)
  "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')] $Message"
}

# Show-Usage: ayuda a STDOUT.
function Show-Usage {
  @'
Usage: .\CreateAndDeployDockerImage.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p> -DockerImageTag <t> -EnvFile <f> -DockerComposeFile <f>
  Actualiza DOCKER_IMAGE_TAG por clave y redespliega con docker compose.
'@
}

if ($SSHPrivateKeyPath -eq '-h' -or $SSHPrivateKeyPath -eq '--help') { Show-Usage; exit 0 }

if ([string]::IsNullOrEmpty($SSHPrivateKeyPath) -or [string]::IsNullOrEmpty($SSHUser) -or
    [string]::IsNullOrEmpty($SSHHost) -or [string]::IsNullOrEmpty($RemoteRepositoryPath) -or
    [string]::IsNullOrEmpty($DockerImageTag) -or [string]::IsNullOrEmpty($EnvFile) -or
    [string]::IsNullOrEmpty($DockerComposeFile)) {
  [Console]::Error.WriteLine('Usage: .\CreateAndDeployDockerImage.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p> -DockerImageTag <t> -EnvFile <f> -DockerComposeFile <f>')
  exit 2
}

$sshBase = @('-o', 'StrictHostKeyChecking=yes', '-o', 'BatchMode=yes', '-i', $SSHPrivateKeyPath)
$target = "$SSHUser@$SSHHost"

Write-Log "Updating DOCKER_IMAGE_TAG=$DockerImageTag in $EnvFile (by key)"
$updateCmd = "cd '$RemoteRepositoryPath' && awk -v k=DOCKER_IMAGE_TAG -v v='$DockerImageTag' 'BEGIN{FS=OFS=`"=`"} `$1==k{`$2=v;f=1}{print} END{if(!f)print k`"=`"v}' '$EnvFile' > '$EnvFile'.tmp && mv '$EnvFile'.tmp '$EnvFile' && grep '^DOCKER_IMAGE_TAG=' '$EnvFile'"
& ssh @sshBase $target $updateCmd

Write-Log "Stopping services with $DockerComposeFile"
& ssh @sshBase $target "cd '$RemoteRepositoryPath' && docker compose -f '$DockerComposeFile' --env-file='$EnvFile' down"

Write-Log "Starting services with $DockerComposeFile"
& ssh @sshBase $target "cd '$RemoteRepositoryPath' && docker compose -f '$DockerComposeFile' --env-file='$EnvFile' up --build -d; echo `$?"

Write-Log "Deployed tag: $DockerImageTag"
