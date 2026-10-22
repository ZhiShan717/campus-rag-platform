[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$env:HF_HOME = Join-Path $workspaceRoot '.local\huggingface-cache'
$env:HF_HUB_OFFLINE = '1'
$env:TRANSFORMERS_OFFLINE = '1'
$env:TOKENIZERS_PARALLELISM = 'false'
& (Join-Path $PSScriptRoot 'Start-ModelService.ps1')
& (Join-Path $workspaceRoot '.venv\Scripts\python.exe') (Join-Path $PSScriptRoot 'model-verify.py')
if ($LASTEXITCODE -ne 0) { throw 'A model check failed. See the output above.' }
