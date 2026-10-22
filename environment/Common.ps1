Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Isolated CLI configuration: do not modify the desktop user's Docker settings.
$env:DOCKER_CONFIG = Join-Path (Split-Path $PSScriptRoot -Parent) '.local\docker-cli'
$env:DOCKER_CONTEXT = 'desktop-linux'
$env:DOCKER_HOST = $null
$env:DOCKER_TLS_VERIFY = $null
$env:DOCKER_CERT_PATH = $null
foreach ($dockerBin in @((Join-Path (Split-Path $PSScriptRoot -Parent) '.local\DockerDesktop\resources\bin'), 'C:\Program Files\Docker\Docker\resources\bin')) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $dockerBin 'docker.exe'))) {
        $env:Path = $dockerBin + [IO.Path]::PathSeparator + $env:Path
    }
}

function Get-CampusComposeArguments {
    param([switch]$Messaging)
    $arguments = @('compose', '--project-name', 'campus-rag-dev', '--project-directory', $PSScriptRoot, '--env-file', (Join-Path $PSScriptRoot '.env'), '--file', (Join-Path $PSScriptRoot 'docker-compose.yml'))
    if ($Messaging) { $arguments += @('--profile', 'messaging') }
    return $arguments
}

function Read-CampusSecrets {
    $path = Join-Path $PSScriptRoot '.env'
    if (-not (Test-Path -LiteralPath $path)) { throw 'Run Initialize-Environment.ps1 first.' }
    $result = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($path)) {
        if ($line -match '^([A-Z][A-Z0-9_]*)=(.*)$') { $result[$Matches[1]] = $Matches[2] }
    }
    return $result
}

function Get-CampusDockerContainerType {
    param([ValidateRange(1, 15000)][int]$TimeoutMilliseconds = 15000)
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker CLI is unavailable. Start Docker Desktop and reopen PowerShell.' }
    $probeInfo = [Diagnostics.ProcessStartInfo]::new()
    $probeInfo.FileName = (Get-Command docker).Source
    $probeInfo.Arguments = 'info --format {{.OSType}}'
    $probeInfo.UseShellExecute = $false
    $probeInfo.CreateNoWindow = $true
    $probeInfo.RedirectStandardOutput = $true
    $probeInfo.RedirectStandardError = $true
    $probe = [Diagnostics.Process]::Start($probeInfo)
    try {
        if (-not $probe.WaitForExit($TimeoutMilliseconds)) {
            $probe.Kill()
            throw 'Docker Engine readiness probe timed out.'
        }
        if ($probe.ExitCode -ne 0) { throw 'Docker daemon returned an error.' }
        return $probe.StandardOutput.ReadToEnd().Trim()
    } finally { $probe.Dispose() }
}

function Assert-CampusDocker {
    param([ValidateRange(1, 15000)][int]$ProbeTimeoutMilliseconds = 15000)
    try {
        $containerType = Get-CampusDockerContainerType -TimeoutMilliseconds $ProbeTimeoutMilliseconds
    } catch { throw 'Docker Engine is unavailable. Start Docker Desktop with Linux containers.' }
    if ($containerType -ne 'linux') { throw 'Switch Docker Desktop to Linux containers before starting these services.' }
    try {
        $null = & docker compose version 2>$null
        if ($LASTEXITCODE -ne 0) { throw 'Compose plugin unavailable.' }
    } catch { throw 'The Docker Compose plugin is unavailable. Run Initialize-ContainerClient.ps1.' }
}

function Wait-CampusDocker {
    param([ValidateRange(15, 600)][int]$TimeoutSeconds = 120)
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    Write-Host 'Waiting for the local Docker Engine to become ready...'
    do {
        $remainingMilliseconds = [int][Math]::Floor(($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        if ($remainingMilliseconds -le 0) { break }
        try { Assert-CampusDocker -ProbeTimeoutMilliseconds ([Math]::Min(15000, $remainingMilliseconds)); return } catch { }
        $remainingMilliseconds = [int][Math]::Floor(($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        if ($remainingMilliseconds -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(3000, $remainingMilliseconds)) }
    } while ([DateTime]::UtcNow -lt $deadline)
    throw 'Docker Engine did not become ready within the timeout. Check Docker Desktop, then retry.'
}

function Set-CampusNacosPassword {
    $secrets = Read-CampusSecrets
    $loginUri = 'http://127.0.0.1:8848/nacos/v1/auth/login'
    $loginArguments = @{Method = 'Post'; Uri = $loginUri; ContentType = 'application/x-www-form-urlencoded'; TimeoutSec = 15; ErrorAction = 'Stop'; Verbose = $false; Debug = $false}
    try {
        $existing = Invoke-RestMethod @loginArguments -Body @{username = 'nacos'; password = $secrets.NACOS_ADMIN_PASSWORD}
        if ($existing.accessToken) { return }
    } catch { }
    try {
        # Nacos 2.3.2 ships nacos/nacos; rotate it only on a newly initialized volume.
        # No response/token or error response body is written to the console.
        $initial = Invoke-RestMethod @loginArguments -Body @{username = 'nacos'; password = 'nacos'}
        if (-not $initial.accessToken) { throw 'No authentication token.' }
        $headers = @{Authorization = 'Bearer ' + $initial.accessToken}
        $null = Invoke-RestMethod -Method Put -Uri 'http://127.0.0.1:8848/nacos/v1/auth/users' -Headers $headers -ContentType 'application/x-www-form-urlencoded' -Body @{username = 'nacos'; newPassword = $secrets.NACOS_ADMIN_PASSWORD} -TimeoutSec 15 -ErrorAction Stop -Verbose:$false -Debug:$false
        $verified = Invoke-RestMethod @loginArguments -Body @{username = 'nacos'; password = $secrets.NACOS_ADMIN_PASSWORD}
        if (-not $verified.accessToken) { throw 'Password verification failed.' }
    } catch {
        throw 'Nacos administrator password initialization failed. Check its health and retain the original .env for existing volumes. No token or password was printed.'
    }
}
