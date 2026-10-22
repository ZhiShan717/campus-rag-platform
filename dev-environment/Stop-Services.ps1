[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-CampusDocker
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.env'))) { throw 'The original .env is required to safely address this Compose environment.' }
$composeArguments = @(Get-CampusComposeArguments -Messaging)
# Deliberately omit --volumes. Databases and other persisted data are retained.
& docker @composeArguments down --remove-orphans
if ($LASTEXITCODE -ne 0) { throw 'Stopping campus-rag-dev failed.' }
Write-Host 'campus-rag-dev stopped. Persistent volumes and credentials were retained.'
