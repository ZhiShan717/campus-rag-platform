[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$stateDirectory = Join-Path $workspaceRoot '.setup\state'
$logDirectory = Join-Path $workspaceRoot '.setup\logs'
$statePath = Join-Path $stateDirectory 'ollama-process.json'
try {
    $existingApi = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 3 -ErrorAction Stop
    if ($existingApi.version) {
        Write-Host ('Ollama is already available at http://127.0.0.1:11434 (version ' + $existingApi.version + ').')
        return
    }
} catch { }
$ollamaCommand = Get-Command ollama -ErrorAction Stop
$listener = [Net.Sockets.TcpClient]::new()
try {
    $listener.Connect('127.0.0.1', 11434)
    throw 'Port 11434 is occupied by a service that did not answer the Ollama version API.'
} catch [Net.Sockets.SocketException] {
    # Connection refused means the port is available; do not terminate any listener.
} finally { $listener.Dispose() }
New-Item -ItemType Directory -Path $stateDirectory, $logDirectory, $env:OLLAMA_MODELS -Force | Out-Null
$process = Start-Process -FilePath $ollamaCommand.Source -ArgumentList 'serve' -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logDirectory 'ollama-stdout.log') -RedirectStandardError (Join-Path $logDirectory 'ollama-stderr.log')
$record = @{ Pid = $process.Id; StartTimeUtc = $process.StartTime.ToUniversalTime().ToString('o'); Executable = $ollamaCommand.Source }
$record | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $process.Refresh()
    if ($process.HasExited) { throw 'Ollama exited before becoming ready. See .setup\logs\ollama-stderr.log.' }
    try {
        $readyApi = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 2 -ErrorAction Stop
        if ($readyApi.version) {
            Write-Host ('Ollama is ready at http://127.0.0.1:11434 (version ' + $readyApi.version + ').')
            Write-Host ('Model storage: ' + $env:OLLAMA_MODELS)
            return
        }
    } catch { }
    Start-Sleep -Milliseconds 500
}
throw 'Ollama did not become ready. See .setup\logs\ollama-stderr.log.'
