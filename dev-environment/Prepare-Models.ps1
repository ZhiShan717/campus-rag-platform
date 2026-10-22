[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $workspaceRoot '.venv\Scripts\python.exe'
& (Join-Path $PSScriptRoot 'Install-ModelDependencies.ps1')
& $python -u (Join-Path $PSScriptRoot 'model-download.py')
if ($LASTEXITCODE -ne 0) { throw 'The BAAI model download or verification failed.' }
& (Join-Path $PSScriptRoot 'Start-ModelService.ps1')
& $python -u (Join-Path $PSScriptRoot 'model-pull-ollama.py')
if ($LASTEXITCODE -ne 0) { throw 'The Ollama model download failed.' }
& (Join-Path $PSScriptRoot 'Test-Models.ps1')
