[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
. (Join-Path $PSScriptRoot 'Common.ps1')
& (Join-Path $PSScriptRoot 'Initialize-ContainerClient.ps1')
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$localRoot = Join-Path $workspaceRoot '.local'
$desktopCandidates = @(
    (Join-Path $localRoot 'DockerDesktop\Docker Desktop.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\Docker Desktop.exe'),
    (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe')
)
$desktopPath = $desktopCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $desktopPath) { throw 'Docker Desktop is not installed in a known location.' }

# Only the launched Docker process receives these profile paths. The encrypted
# Windows roaming profile on this computer cannot perform Docker's atomic rename.
$isolatedProfile = Join-Path $localRoot 'docker-profile'
$isolatedRoaming = Join-Path $isolatedProfile 'Roaming'
$isolatedLocal = Join-Path $isolatedProfile 'Local'
$isolatedDocker = Join-Path $isolatedRoaming 'Docker'
New-Item -ItemType Directory -Path $isolatedRoaming, $isolatedLocal, $isolatedDocker, $env:DOCKER_CONFIG -Force | Out-Null
$originalSettings = Join-Path $env:APPDATA 'Docker\install-settings.json'
$isolatedSettings = Join-Path $isolatedDocker 'install-settings.json'
if ((Test-Path -LiteralPath $originalSettings) -and -not (Test-Path -LiteralPath $isolatedSettings)) {
    [IO.File]::WriteAllText($isolatedSettings, [IO.File]::ReadAllText($originalSettings), [Text.UTF8Encoding]::new($false))
}

# Pin the original data disk. An installer-provided wslDefaultDataRoot can
# otherwise redirect this profile to a fresh disk and hide existing volumes.
$dockerDataRoot = Join-Path $isolatedLocal 'Docker\wsl'
$installSettings = if (Test-Path -LiteralPath $isolatedSettings) {
    [IO.File]::ReadAllText($isolatedSettings) | ConvertFrom-Json
} else { [pscustomobject]@{} }
$dataRootProperty = $installSettings.PSObject.Properties['wslDefaultDataRoot']
$dataRootChanged = -not $dataRootProperty -or $dataRootProperty.Value -ne $dockerDataRoot

# Share the bounded probe used by normal service and dashboard startup.
$engineRunning = $false
try {
    $engineRunning = (Get-CampusDockerContainerType) -eq 'linux'
} catch { }
if ($dataRootChanged -and $engineRunning) {
    throw 'Docker is running with an unverified data-directory setting. Quit Docker Desktop, then run this launcher again to restore the original data disk safely.'
}
if ($dataRootChanged) {
    if (Test-Path -LiteralPath $isolatedSettings) {
        $backupPath = $isolatedSettings + '.before-data-root-fix-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak'
        Copy-Item -LiteralPath $isolatedSettings -Destination $backupPath
    }
    $installSettings | Add-Member -NotePropertyName 'wslDefaultDataRoot' -NotePropertyValue $dockerDataRoot -Force
    [IO.File]::WriteAllText($isolatedSettings, ($installSettings | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
}
if ($engineRunning) {
    Write-Host 'Docker Engine is already running with Linux containers.'
    return
}
$processInfo = [Diagnostics.ProcessStartInfo]::new()
$processInfo.FileName = $desktopPath
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true
$processInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$processInfo.EnvironmentVariables['APPDATA'] = $isolatedRoaming
$processInfo.EnvironmentVariables['LOCALAPPDATA'] = $isolatedLocal
$processInfo.EnvironmentVariables['DOCKER_CONFIG'] = $env:DOCKER_CONFIG
$process = [Diagnostics.Process]::Start($processInfo)
Write-Host ('Docker Desktop start requested (process ' + $process.Id + ').')
Write-Host 'Docker Engine can take several dozen seconds to start. Run Check-Environment.ps1 after it finishes.'
