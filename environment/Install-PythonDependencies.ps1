[CmdletBinding()]
param([switch]$Resolve)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $workspaceRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) { throw 'Create the workspace Python 3.11 virtual environment first.' }
$lock = Join-Path $PSScriptRoot 'requirements-rag.lock.txt'
$requirements = if ($Resolve -or -not (Test-Path -LiteralPath $lock)) {
    Join-Path $PSScriptRoot 'requirements-rag.in'
} else { $lock }

# Package changes are limited to this workspace. Use the existing Windows proxy
# only when a process proxy was not supplied; never change Windows settings.
$env:PIP_CACHE_DIR = Join-Path $workspaceRoot '.setup\pip-cache'
$savedHttpsProxy = $env:HTTPS_PROXY
try {
    if (-not $env:HTTPS_PROXY) {
        $proxy = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
        if ($proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer -match '^[A-Za-z0-9.-]+:\d+$') {
            $env:HTTPS_PROXY = 'http://' + $proxy.ProxyServer
        }
    }
    & $python -m pip install --index-url https://pypi.org/simple --requirement $requirements
    if ($LASTEXITCODE -ne 0) { throw 'Python dependency installation failed.' }
    & $python -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'Python dependency compatibility check failed.' }
    & $python (Join-Path $PSScriptRoot 'Test-PythonDependencies.py')
    if ($LASTEXITCODE -ne 0) { throw 'Python SDK offline smoke check failed.' }
} finally {
    $env:HTTPS_PROXY = $savedHttpsProxy
}
Write-Host 'Python development dependencies are ready in the workspace virtual environment.'
