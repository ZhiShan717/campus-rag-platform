[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $workspaceRoot '.venv\Scripts\python.exe'
$wheelDirectory = Join-Path $workspaceRoot '.local\model-wheels'
$wheel = Join-Path $wheelDirectory 'torch-2.14.1+cpu-cp311-cp311-win_amd64.whl'
$expectedHash = 'D14B0C8A66345B7BA43ADFA86FC20D89087A0A92E440004755D49D2468DDC6E0'
$env:PIP_CACHE_DIR = Join-Path $workspaceRoot '.local\pip-cache'
$sdkLock = Join-Path $PSScriptRoot 'requirements-rag.lock.txt'
$modelLock = Join-Path $PSScriptRoot 'requirements-models.lock.txt'
if (-not (Test-Path -LiteralPath $python)) { throw 'The project Python 3.11 virtual environment is missing.' }
if (-not (Test-Path -LiteralPath $modelLock)) { throw 'The model dependency lock file is missing.' }
New-Item -ItemType Directory -Path $wheelDirectory -Force | Out-Null
$savedHttpsProxy = $env:HTTPS_PROXY
$savedUvCache = $env:UV_CACHE_DIR
try {
    if (-not $env:HTTPS_PROXY) {
        $proxy = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
        if ($proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer -match '^[A-Za-z0-9.-]+:\d+$') {
            $env:HTTPS_PROXY = 'http://' + $proxy.ProxyServer
        }
    }
    if (-not (Test-Path -LiteralPath $wheel)) {
        & $python -m pip download 'torch==2.14.1+cpu' --no-deps --index-url 'https://download.pytorch.org/whl/cpu' --dest $wheelDirectory --timeout 60 --retries 5
        if ($LASTEXITCODE -ne 0) { throw 'The official CPU PyTorch wheel download failed.' }
    }
    if ((Get-FileHash -LiteralPath $wheel -Algorithm SHA256).Hash -ne $expectedHash) {
        throw 'The cached CPU PyTorch wheel does not match the verified official download SHA256.'
    }
    & $python -u (Join-Path $PSScriptRoot 'model-download-wheels.py')
    if ($LASTEXITCODE -ne 0) { throw 'The official PyPI dependency download or SHA256 verification failed.' }
    $wheelRecords = Get-Content -LiteralPath (Join-Path $wheelDirectory 'pypi-download-record.json') -Raw | ConvertFrom-Json
    $localWheels = @($wheel) + @($wheelRecords | ForEach-Object { Join-Path $wheelDirectory $_.filename })
    $uv = Join-Path $workspaceRoot '.venv\Scripts\uv.exe'
    if (Test-Path -LiteralPath $uv) {
        $env:UV_CACHE_DIR = Join-Path $workspaceRoot '.local\uv-cache'
        & $uv pip install --python $python @localWheels --requirement $modelLock --constraint $sdkLock --index-url 'https://pypi.org/simple'
    } else {
        & $python -m pip install @localWheels --requirement $modelLock --constraint $sdkLock --index-url 'https://pypi.org/simple' --timeout 60 --retries 5
    }
    if ($LASTEXITCODE -ne 0) { throw 'Model dependency installation failed.' }
    & $python -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'Installed Python dependencies are inconsistent.' }
} finally {
    $env:HTTPS_PROXY = $savedHttpsProxy
    $env:UV_CACHE_DIR = $savedUvCache
}
Write-Host 'CPU model dependencies are installed and consistent with the RAG SDK lock.'
