[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Start-Services.ps1') -Messaging
& (Join-Path $PSScriptRoot 'Start-ModelService.ps1')
Write-Host 'Owner development infrastructure and Ollama API are ready. Application services require project source code.'
