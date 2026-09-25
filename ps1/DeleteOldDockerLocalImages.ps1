# ==============================================================================
# Description: Normaliza fin de linea y ejecuta la limpieza de imagenes
#   Docker locales en el servidor remoto (conserva las 3 mas recientes),
#   con SSH endurecido y validacion temprana de parametros.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: .\DeleteOldDockerLocalImages.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p>
# Env Vars: ninguna requerida (todo por parametros).
# Dependencies: PowerShell 5.1+, ssh (OpenSSH); en remoto: bash, docker
# Exit codes: 0 ok; 2 uso/argumentos invalidos; 1 error operativo.
# ==============================================================================

$ErrorActionPreference = 'Stop'

param(
  [string]$SSHPrivateKeyPath = '',
  [string]$SSHUser = '',
  [string]$SSHHost = '',
  [string]$RemoteRepositoryPath = ''
)

# Write-Log: imprime un mensaje con timestamp ISO-8601 UTC.
function Write-Log {
  param([string]$Message)
  "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')] $Message"
}

# Show-Usage: ayuda a STDOUT.
function Show-Usage {
  @'
Usage: .\DeleteOldDockerLocalImages.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p>
  Limpia imagenes locales viejas en el remoto (conserva las 3 mas recientes).
'@
}

if ($SSHPrivateKeyPath -eq '-h' -or $SSHPrivateKeyPath -eq '--help') { Show-Usage; exit 0 }

if ([string]::IsNullOrEmpty($SSHPrivateKeyPath) -or [string]::IsNullOrEmpty($SSHUser) -or
    [string]::IsNullOrEmpty($SSHHost) -or [string]::IsNullOrEmpty($RemoteRepositoryPath)) {
  [Console]::Error.WriteLine('Usage: .\DeleteOldDockerLocalImages.ps1 -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RemoteRepositoryPath <p>')
  exit 2
}

$sshBase = @('-o', 'StrictHostKeyChecking=yes', '-o', 'BatchMode=yes', '-i', $SSHPrivateKeyPath)
$target = "$SSHUser@$SSHHost"

Write-Log "Cleaning old local Docker images on $target (keep 3 most recent)"
& ssh @sshBase $target "cd '$RemoteRepositoryPath/sh' && sed -i 's/`r`$//' deleteOldDockerLocalImages.sh && bash deleteOldDockerLocalImages.sh"
Write-Log 'Remote cleanup finished.'
