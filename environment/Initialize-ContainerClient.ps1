[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$clientDirectory = Join-Path $workspaceRoot '.local\docker-cli'
$configPath = Join-Path $clientDirectory 'config.json'
$pluginCandidates = @(
    (Join-Path $workspaceRoot '.local\DockerDesktop\resources\cli-plugins'),
    (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\cli-plugins'),
    (Join-Path $env:ProgramFiles 'Docker\Docker\resources\cli-plugins')
)
$pluginDirectories = @($pluginCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container })
if (-not $pluginDirectories.Count) { throw 'Docker Desktop CLI plugin directory was not found.' }
New-Item -ItemType Directory -Path $clientDirectory -Force | Out-Null
if (Test-Path -LiteralPath $configPath) {
    $config = [IO.File]::ReadAllText($configPath) | ConvertFrom-Json
    if (-not $config) { throw 'Docker client configuration is empty; it was preserved.' }
} else { $config = [pscustomobject]@{} }
$existing = @()
if ($config.PSObject.Properties.Name -contains 'cliPluginsExtraDirs') {
    $existing = @($config.cliPluginsExtraDirs)
}
$combined = @($pluginDirectories + $existing | Select-Object -Unique)
if ($existing.Count -eq $combined.Count -and @($combined | Where-Object { $_ -notin $existing }).Count -eq 0) { return }
$config | Add-Member -NotePropertyName 'cliPluginsExtraDirs' -NotePropertyValue $combined -Force
$temporaryPath = Join-Path $clientDirectory ('config-' + [Guid]::NewGuid().ToString('N') + '.tmp')
try {
    [IO.File]::WriteAllText($temporaryPath, ($config | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $configPath -Force
} finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
}
