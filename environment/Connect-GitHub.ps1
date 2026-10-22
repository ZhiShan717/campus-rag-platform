param(
    [switch]$CreateRepository,
    [string]$ExpectedAccount = 'ZhiShan717',
    [string]$Repository = 'campus-rag-platform'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$gh = Join-Path $projectRoot '.local\GitHubCLI\bin\gh.exe'
if (-not (Test-Path -LiteralPath $gh)) {
    throw 'GitHub CLI is missing. Run the verified local installer first.'
}
if ($ExpectedAccount -notmatch '^[A-Za-z0-9-]+$' -or $Repository -notmatch '^[A-Za-z0-9_.-]+$') {
    throw 'Invalid GitHub account or repository name.'
}

# GitHub CLI uses proxy environment variables; Windows browsers use this registry setting.
$savedHttpProxy = $env:HTTP_PROXY
$savedHttpsProxy = $env:HTTPS_PROXY
try {
    if (-not $env:HTTPS_PROXY) {
        $settings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
        if ($settings.ProxyEnable -eq 1 -and $settings.ProxyServer -match '^127\.0\.0\.1:\d+$') {
            $env:HTTPS_PROXY = 'http://' + $settings.ProxyServer
            if (-not $env:HTTP_PROXY) { $env:HTTP_PROXY = $env:HTTPS_PROXY }
        }
    }

    # Never print, read, or pass authentication tokens. gh stores credentials in Windows Credential Manager.
    & $gh auth status --hostname github.com *> $null
    if ($LASTEXITCODE -ne 0) {
        & $gh auth login --web --git-protocol https --hostname github.com
        if ($LASTEXITCODE -ne 0) { throw 'GitHub browser sign-in did not complete.' }
    }
    $account = (& $gh api user --jq .login).Trim()
    if ($LASTEXITCODE -ne 0 -or $account -cne $ExpectedAccount) {
        throw "Expected GitHub account '$ExpectedAccount'; authenticated account is '$account'. No repository was created."
    }
    Write-Host "Signed in as $account."
    if (-not $CreateRepository) { return }

    $fullName = "$ExpectedAccount/$Repository"
    $existingJson = & $gh repo view $fullName --json nameWithOwner,isPrivate,url 2>$null
    $viewExit = $LASTEXITCODE
    if ($viewExit -eq 0) {
        $existing = $existingJson | ConvertFrom-Json
        if (-not $existing.isPrivate) { throw 'The existing repository is public. Its visibility was not changed.' }
        Write-Output $existing.url
        return
    }

    # Creates an empty private repository. This script never commits or pushes local files.
    & $gh repo create $fullName --private --description 'Campus RAG platform project and local development environment'
    if ($LASTEXITCODE -ne 0) { throw 'Repository creation failed; verify GitHub connectivity and account permissions.' }
    $createdJson = & $gh repo view $fullName --json nameWithOwner,isPrivate,url
    if ($LASTEXITCODE -ne 0) { throw 'Repository was created but verification did not finish.' }
    $created = $createdJson | ConvertFrom-Json
    if (-not $created.isPrivate) { throw 'Repository privacy verification failed.' }
    Write-Output $created.url
}
finally {
    $env:HTTP_PROXY = $savedHttpProxy
    $env:HTTPS_PROXY = $savedHttpsProxy
}
