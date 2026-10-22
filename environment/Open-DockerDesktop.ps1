[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $workspaceRoot '.setup\logs'
$logPath = Join-Path $logDirectory 'docker-desktop-launch.log'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

try {
    & (Join-Path $PSScriptRoot 'Start-ContainerEngine.ps1') *>> $logPath
    . (Join-Path $PSScriptRoot 'Common.ps1')
    Wait-CampusDocker -TimeoutSeconds 180 *>> $logPath

    $desktopPath = Join-Path $workspaceRoot '.local\DockerDesktop\Docker Desktop.exe'
    if (-not (Test-Path -LiteralPath $desktopPath)) {
        throw 'The Docker Desktop application could not be found.'
    }
    # The dashboard must use the same profile as the running backend.
    $profileRoot = Join-Path $workspaceRoot '.local\docker-profile'
    $processInfo = [Diagnostics.ProcessStartInfo]::new()
    $processInfo.FileName = $desktopPath
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Normal
    $processInfo.EnvironmentVariables['APPDATA'] = Join-Path $profileRoot 'Roaming'
    $processInfo.EnvironmentVariables['LOCALAPPDATA'] = Join-Path $profileRoot 'Local'
    $processInfo.EnvironmentVariables['DOCKER_CONFIG'] = $env:DOCKER_CONFIG
    [void][Diagnostics.Process]::Start($processInfo)
} catch {
    ('[' + [DateTime]::Now.ToString('s') + '] ' + $_.Exception.Message) | Add-Content -LiteralPath $logPath
    Add-Type -AssemblyName System.Windows.Forms
    [void][Windows.Forms.MessageBox]::Show(
        ('Docker Desktop 启动失败。请查看日志：' + [Environment]::NewLine + $logPath),
        'Docker Desktop',
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}
