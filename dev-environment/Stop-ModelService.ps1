[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $workspaceRoot '.setup\state\ollama-process.json'
if (-not (Test-Path -LiteralPath $statePath)) {
    Write-Host 'No Ollama process started by Start-ModelService.ps1 is recorded.'
    return
}
$record = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$process = Get-Process -Id $record.Pid -ErrorAction SilentlyContinue
if (-not $process) {
    Remove-Item -LiteralPath $statePath -Force
    Write-Host 'The recorded Ollama process is no longer running.'
    return
}
$actualStartTime = $process.StartTime.ToUniversalTime().ToString('o')
if ($process.ProcessName -ne 'ollama' -or $actualStartTime -ne $record.StartTimeUtc -or $process.Path -ne $record.Executable) {
    throw 'The recorded process identity no longer matches. No process was stopped.'
}
Stop-Process -Id $process.Id -ErrorAction Stop
Remove-Item -LiteralPath $statePath -Force
Write-Host 'The Ollama process started by this environment has been stopped.'
