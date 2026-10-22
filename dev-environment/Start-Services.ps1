[CmdletBinding()]
param([switch]$Messaging, [switch]$Rebuild, [ValidateRange(60, 1800)][int]$WaitTimeout = 360)

. (Join-Path $PSScriptRoot 'Common.ps1')
& (Join-Path $PSScriptRoot 'Initialize-Environment.ps1')
$engineLauncher = Join-Path $PSScriptRoot 'Start-ContainerEngine.ps1'
if (Test-Path -LiteralPath $engineLauncher) { & $engineLauncher }
Wait-CampusDocker -TimeoutSeconds 120
$composeArguments = @(Get-CampusComposeArguments -Messaging:$Messaging)
# Quiet validation prevents passwords from being expanded into the console.
& docker @composeArguments config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Compose configuration validation failed.' }
# Reuse the local IK image on daily startup. An unnecessary build can contact
# the upstream image registry even when every required image is already cached.
$savedPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $null = & docker image inspect --format '{{.Id}}' 'campus-rag-dev/elasticsearch-ik:8.11.4' 2>$null
    $ikImageAvailable = $LASTEXITCODE -eq 0
} finally { $ErrorActionPreference = $savedPreference }
$upArguments = @('up', '--detach', '--wait', '--wait-timeout', $WaitTimeout)
if ($Rebuild -or -not $ikImageAvailable) {
    $upArguments += '--build'
    Write-Host 'Building the matching Elasticsearch IK image for this startup.'
} else {
    $upArguments += '--no-build'
    Write-Host 'Using the existing Elasticsearch IK image without rebuilding.'
}
Write-Host 'Starting independent campus-rag-dev infrastructure.'
if ($Messaging) { Write-Host 'Optional RocketMQ is enabled; allow about 1.4 GiB additional container memory.' }
& docker @composeArguments @upArguments
if ($LASTEXITCODE -ne 0) { throw 'Infrastructure startup failed. Check Docker Desktop and container health; persisted volumes were retained.' }
Set-CampusNacosPassword
& (Join-Path $PSScriptRoot 'Test-Services.ps1') -Messaging:$Messaging
Write-Host 'Development infrastructure is ready on 127.0.0.1. Credentials are in the protected .env file.'
