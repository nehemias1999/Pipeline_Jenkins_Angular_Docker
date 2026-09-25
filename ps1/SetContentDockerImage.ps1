# ==============================================================================
# Description: Prepara el paquete de despliegue copiando los archivos
#   requeridos al directorio 'deploy' y transfiriendolos al servidor remoto
#   via SCP, con SSH endurecido. Espejo portable del .bat original.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: .\SetContentDockerImage.ps1 -PipelinePath <p> -ApplicationPath <p> -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RepositoryPath <p>
# Env Vars: ninguna requerida (todo por parametros).
# Dependencies: PowerShell 5.1+, ssh, scp (OpenSSH)
# Exit codes: 0 ok; 2 uso/argumentos invalidos; 1 error operativo.
# ==============================================================================

$ErrorActionPreference = 'Stop'

param(
  [string]$PipelinePath = '',
  [string]$ApplicationPath = '',
  [string]$SSHPrivateKeyPath = '',
  [string]$SSHUser = '',
  [string]$SSHHost = '',
  [string]$RepositoryPath = ''
)

# Write-Log: imprime un mensaje con timestamp ISO-8601 UTC.
function Write-Log {
  param([string]$Message)
  "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')] $Message"
}

# Show-Usage: ayuda a STDOUT.
function Show-Usage {
  @'
Usage: .\SetContentDockerImage.ps1 -PipelinePath <p> -ApplicationPath <p> -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RepositoryPath <p>
  Prepara 'deploy' y lo transfiere al servidor remoto via SCP.
'@
}

if ($PipelinePath -eq '-h' -or $PipelinePath -eq '--help') { Show-Usage; exit 0 }

if ([string]::IsNullOrEmpty($PipelinePath) -or [string]::IsNullOrEmpty($ApplicationPath) -or
    [string]::IsNullOrEmpty($SSHPrivateKeyPath) -or [string]::IsNullOrEmpty($SSHUser) -or
    [string]::IsNullOrEmpty($SSHHost) -or [string]::IsNullOrEmpty($RepositoryPath)) {
  [Console]::Error.WriteLine('Usage: .\SetContentDockerImage.ps1 -PipelinePath <p> -ApplicationPath <p> -SSHPrivateKeyPath <p> -SSHUser <u> -SSHHost <h> -RepositoryPath <p>')
  exit 2
}

$sshBase = @('-o', 'StrictHostKeyChecking=yes', '-o', 'BatchMode=yes', '-i', $SSHPrivateKeyPath)
$target = "$SSHUser@$SSHHost"

Write-Log "Preparing deploy package in $PipelinePath\deploy"
New-Item -ItemType Directory -Force -Path "$PipelinePath\deploy" | Out-Null

if (Test-Path "$ApplicationPath\src") {
  New-Item -ItemType Directory -Force -Path "$PipelinePath\deploy\src" | Out-Null
  Copy-Item -Recurse -Force "$ApplicationPath\src\*" "$PipelinePath\deploy\src\"
  Write-Log "Copied $ApplicationPath\src"
} else {
  Write-Log "WARNING: missing $ApplicationPath\src, skipped"
}

foreach ($f in @('angular.json', 'package.json', 'package-lock.json', 'tsconfig.app.json', 'tsconfig.json', 'tsconfig.spec.json')) {
  if (Test-Path "$ApplicationPath\$f") {
    Copy-Item -Force "$ApplicationPath\$f" "$PipelinePath\deploy\"
    Write-Log "Copied $f"
  } else {
    Write-Log "WARNING: missing $ApplicationPath\$f, skipped"
  }
}

if (Test-Path "$PipelinePath\docker") {
  Copy-Item -Recurse -Force "$PipelinePath\docker\*" "$PipelinePath\deploy\"
  Write-Log "Copied $PipelinePath\docker"
} else {
  Write-Log "WARNING: missing $PipelinePath\docker, skipped"
}

if (Test-Path "$PipelinePath\sh") {
  New-Item -ItemType Directory -Force -Path "$PipelinePath\deploy\sh" | Out-Null
  Copy-Item -Recurse -Force "$PipelinePath\sh\*" "$PipelinePath\deploy\sh\"
  Write-Log "Copied $PipelinePath\sh"
} else {
  Write-Log "WARNING: missing $PipelinePath\sh, skipped"
}

if ([string]::IsNullOrEmpty($RepositoryPath) -or $RepositoryPath -eq '/') {
  [Console]::Error.WriteLine('ERROR: RepositoryPath must not be empty or root.')
  exit 2
}

Write-Log "Cleaning remote directory $RepositoryPath (guarded rm)"
& ssh @sshBase "$target" "[ -n '$RepositoryPath' ] && [ '$RepositoryPath' != '/' ] && rm -rf -- '$RepositoryPath/'*"

Write-Log "Copying deploy folder to ${target}:${RepositoryPath}"
& scp -r @sshBase "$PipelinePath\deploy\*" "${target}:${RepositoryPath}/"

Write-Log "Deploy package transferred to ${target}:${RepositoryPath}"
