[CmdletBinding()]
param([switch]$RequireServices)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Enter-DevEnvironment.ps1') -Quiet
$checks = [Collections.Generic.List[object]]::new()

function Add-CampusCheck {
    param([string]$Name, [string]$Status, [string]$Detail)
    $checks.Add([pscustomobject]@{ Component = $Name; Status = $Status; Detail = $Detail })
}

function Test-CampusVersion {
    param([string]$Name, [string]$Command, [string[]]$Arguments, [string]$Expected)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Add-CampusCheck $Name 'MISSING' 'Executable was not found.'
        return
    }
    try {
        # Native commands such as java write their version to standard error.
        $savedPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = (& $Command @Arguments 2>&1 | Out-String).Trim()
        $nativeExitCode = $LASTEXITCODE
        $ErrorActionPreference = $savedPreference
        $firstLine = @($output -split '\r?\n' | Where-Object { $_ -and $_ -notmatch '^Access is denied\.$' })[0]
        if ($nativeExitCode -ne 0 -or $output -notmatch $Expected) {
            Add-CampusCheck $Name 'FAIL' $firstLine
        } else {
            Add-CampusCheck $Name 'PASS' $firstLine
        }
    } catch {
        $ErrorActionPreference = $savedPreference
        Add-CampusCheck $Name 'FAIL' 'Version check could not run.'
    }
}

Test-CampusVersion 'Java' 'java' @('-version') 'version "17\.'
Test-CampusVersion 'Javac' 'javac' @('-version') 'javac 17\.'
Test-CampusVersion 'Maven' 'mvn.cmd' @('-version') 'Apache Maven 3\.([9]|[1-9][0-9])\.'
Test-CampusVersion 'Python' 'python' @('--version') 'Python 3\.11\.'
Test-CampusVersion 'pip' 'python' @('-m', 'pip', '--version') '\(python 3\.11\)'
Test-CampusVersion 'Node.js' 'node' @('--version') '^v(1[89]|[2-9][0-9])\.'
Test-CampusVersion 'npm' 'npm.cmd' @('--version') '^\d+\.'
Test-CampusVersion 'Git' 'git' @('--version') '^git version '
Test-CampusVersion 'GitHub CLI' 'gh' @('--version') '^gh version '
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitNameConfigured = [bool](& git config --get user.name 2>$null)
    $gitEmailConfigured = [bool](& git config --get user.email 2>$null)
    if ($gitNameConfigured -and $gitEmailConfigured) {
        Add-CampusCheck 'Git identity' 'PASS' 'Name and email are configured.'
    } else { Add-CampusCheck 'Git identity' 'FAIL' 'Configure a Git author name and email.' }
}
$venvPython = Join-Path (Split-Path -Parent $PSScriptRoot) '.venv\Scripts\python.exe'
if ((Get-Command python -ErrorAction SilentlyContinue).Source -eq $venvPython) {
    Add-CampusCheck 'Python venv' 'PASS' 'Workspace virtual environment is active.'
} else { Add-CampusCheck 'Python venv' 'FAIL' 'The workspace virtual environment is not active.' }
try {
    $dependencyCheck = & $venvPython (Join-Path $PSScriptRoot 'Test-PythonDependencies.py') 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Python dependency smoke check failed.' }
    $dependencyResult = ($dependencyCheck | Out-String) | ConvertFrom-Json
    if ($dependencyResult.status -ne 'PASS') { throw 'Python dependency smoke check failed.' }
    Add-CampusCheck 'Python SDKs' 'PASS' ('LangChain ' + $dependencyResult.packages.langchain + '; LangGraph ' + $dependencyResult.packages.langgraph + '; FastAPI/MCP/client imports and offline smoke passed.')
    $pipCheck = & $venvPython -m pip check 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'pip check found dependency conflicts.' }
    Add-CampusCheck 'pip consistency' 'PASS' 'No broken requirements found.'
} catch {
    Add-CampusCheck 'Python SDKs' 'FAIL' 'Run dev-environment\Install-PythonDependencies.ps1, then Test-PythonDependencies.py for details.'
}
if (Get-Command code.cmd -ErrorAction SilentlyContinue) {
    Add-CampusCheck 'VS Code' 'PASS' (Get-Command code.cmd).Source
} else { Add-CampusCheck 'VS Code' 'MISSING' 'Executable was not found.' }
$extensionManifest = Join-Path $env:USERPROFILE '.vscode\extensions\extensions.json'
try {
    $installedExtensions = @(Get-Content -LiteralPath $extensionManifest -Raw | ConvertFrom-Json)
    $requiredExtensions = @('vscjava.vscode-java-pack', 'ms-python.python', 'ms-python.vscode-pylance', 'vue.volar')
    $missingExtensions = @($requiredExtensions | Where-Object { $_ -notin $installedExtensions.identifier.id })
    if ($missingExtensions.Count -gt 0) { throw 'Required VS Code extensions are missing.' }
    Add-CampusCheck 'Code extensions' 'PASS' 'Java, Python, Pylance and Vue extensions are installed.'
} catch { Add-CampusCheck 'Code extensions' 'FAIL' 'Check Java, Python, Pylance and Vue extension installation in VS Code.' }
Test-CampusVersion 'Docker CLI' 'docker' @('--version') 'Docker version '
Test-CampusVersion 'Compose' 'docker' @('compose', 'version') 'Docker Compose version v[2-9]\.'

if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        # Use the same bounded readiness probe as the startup entry points.
        $engineType = & {
            . (Join-Path $PSScriptRoot 'Common.ps1')
            Get-CampusDockerContainerType
        }
        if ($engineType -ne 'linux') { throw 'Linux engine is unavailable.' }
        Add-CampusCheck 'Docker Engine' 'PASS' 'Linux containers are available.'
    } catch {
        Add-CampusCheck 'Docker Engine' 'NOT RUNNING' 'Run Start-ContainerEngine.ps1, then repeat this check.'
    }
}
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Add-CampusCheck 'Ollama CLI' 'PASS' (Get-Command ollama).Source
} else { Add-CampusCheck 'Ollama CLI' 'MISSING' 'Executable was not found.' }
try {
    $modelApi = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 5 -ErrorAction Stop
    if (-not $modelApi.version) { throw 'Missing version.' }
    Add-CampusCheck 'Ollama API' 'PASS' ('Version ' + $modelApi.version)
} catch {
    Add-CampusCheck 'Ollama API' 'NOT RUNNING' 'Run Start-ModelService.ps1 when a local model service is needed.'
}

$mysqlPort = 13306
$localEnvPath = Join-Path $PSScriptRoot '.env'
if (Test-Path -LiteralPath $localEnvPath) {
    $portLine = [IO.File]::ReadLines($localEnvPath) | Where-Object { $_ -match '^MYSQL_PORT=([0-9]+)$' } | Select-Object -First 1
    if ($portLine -and $portLine -match '^MYSQL_PORT=([0-9]+)$') { $mysqlPort = [int]$Matches[1] }
}
$services = [ordered]@{ MySQL = $mysqlPort; Redis = 6379; Elasticsearch = 9200; MinIO = 9000; Nacos = 8848; RocketMQ = 9876 }
foreach ($entry in $services.GetEnumerator()) {
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $pendingConnection = $client.BeginConnect('127.0.0.1', [int]$entry.Value, $null, $null)
        $connected = $pendingConnection.AsyncWaitHandle.WaitOne(500)
        if ($connected) { $client.EndConnect($pendingConnection) }
        if ($connected -and $client.Connected) {
            Add-CampusCheck $entry.Key 'LISTENING' ('127.0.0.1:' + $entry.Value + ' (TCP only; run Test-Services.ps1 for health)')
        } else {
            Add-CampusCheck $entry.Key 'NOT RUNNING' ('127.0.0.1:' + $entry.Value)
        }
    } catch {
        Add-CampusCheck $entry.Key 'NOT RUNNING' ('127.0.0.1:' + $entry.Value)
    } finally { $client.Dispose() }
}
$checks | Format-Table -AutoSize -Wrap
if (@($checks | Where-Object { $_.Status -in @('MISSING', 'FAIL') }).Count -gt 0) {
    throw 'One or more installed-tool checks failed. See the table above.'
}
if ($RequireServices) {
    & (Join-Path $PSScriptRoot 'Test-Services.ps1')
}
