[CmdletBinding()]
param(
    [string]$MySqlBin = 'C:\Program Files\MySQL\MySQL Server 8.0\bin'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mysqlServer = Join-Path $MySqlBin 'mysqld.exe'
$mysqlAdmin = Join-Path $MySqlBin 'mysqladmin.exe'
if (!(Test-Path -LiteralPath $mysqlServer)) { throw "mysqld.exe not found: $mysqlServer" }
$maven = (Get-Command mvn.cmd -ErrorAction Stop).Source
$run = Join-Path ([System.IO.Path]::GetTempPath()) ('campus-rag-week1-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $run -Force
$data = Join-Path $run 'data'
$log = Join-Path $run 'server.log'
$optionFile = Join-Path $run 'client.cnf'
$password = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
$init = Join-Path $run 'init.sql'
$utf8 = [System.Text.UTF8Encoding]::new($false)
# Only the isolated process and this directory use these ephemeral credentials.
[System.IO.File]::WriteAllText($init, "ALTER USER 'root'@'localhost' IDENTIFIED BY '$password';", $utf8)
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = $listener.LocalEndpoint.Port
$listener.Stop()
$clientText = "[client]`nhost=127.0.0.1`nport=$port`nuser=root`npassword=$password`ndefault-character-set=utf8mb4`n"
[System.IO.File]::WriteAllText($optionFile, $clientText, $utf8)
$prior = @{}
foreach ($name in @('RAG_TEST_URL','RAG_TEST_USER','RAG_TEST_PASSWORD','RAG_MYSQL_BIN','RAG_MYSQL_OPTIONS','RAG_SNAPSHOT')) {
    $prior[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$server = $null
try {
    Write-Host 'Initializing an isolated MySQL instance (existing service is untouched)...'
    & $mysqlServer --no-defaults --initialize-insecure "--basedir=$(Split-Path $MySqlBin -Parent)" "--datadir=$data" "--log-error=$log"
    if ($LASTEXITCODE -ne 0) { throw "MySQL initialization failed; see $log" }
    $serverArgs = @('--no-defaults', "--basedir=`"$(Split-Path $MySqlBin -Parent)`"", "--datadir=`"$data`"",
        "--log-error=`"$log`"", '--bind-address=127.0.0.1', "--port=$port", '--mysqlx=OFF',
        '--character-set-server=utf8mb4', '--collation-server=utf8mb4_0900_as_ci', "--init-file=`"$init`"")
    $server = Start-Process -FilePath $mysqlServer -ArgumentList $serverArgs -PassThru -WindowStyle Hidden
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    $ready = $false
    do {
        $server.Refresh()
        if ($server.HasExited) { throw "MySQL exited; see $log" }
        & $mysqlAdmin "--defaults-extra-file=$optionFile" --connect-timeout=1 ping 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Milliseconds 300
    } while ([DateTime]::UtcNow -lt $deadline)
    if (!$ready) { throw "MySQL readiness timeout; see $log" }
    $env:RAG_TEST_URL = "jdbc:mysql://127.0.0.1:$port/?allowPublicKeyRetrieval=true&useSSL=false&characterEncoding=UTF-8&connectionTimeZone=Asia/Shanghai"
    $env:RAG_TEST_USER = 'root'
    $env:RAG_TEST_PASSWORD = $password
    $env:RAG_MYSQL_BIN = $MySqlBin
    $env:RAG_MYSQL_OPTIONS = $optionFile
    $snapshotDir = Join-Path $root 'project\database\mysql\snapshots'
    $null = New-Item -ItemType Directory -Path $snapshotDir -Force
    $env:RAG_SNAPSHOT = Join-Path $run 'week1-demo.sql'
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $manage = Join-Path $PSScriptRoot 'Manage-Week1Database.ps1'
    & $manage -Action Initialize -Database campus_rag_week1_cli -Port $port -Password $securePassword -MySqlBin $MySqlBin
    $cliBackup = Join-Path $run 'cli-backup.sql'
    & $manage -Action Backup -Database campus_rag_week1_cli -Port $port -Password $securePassword -MySqlBin $MySqlBin -File $cliBackup
    & $manage -Action Restore -Database campus_rag_week1_cli_restored -Port $port -Password $securePassword -MySqlBin $MySqlBin -File $cliBackup
    & $maven -B -ntp -f (Join-Path $root 'project\database-week1.pom.xml') test
    if ($LASTEXITCODE -ne 0) { throw 'Week 1 database verification failed.' }
    Copy-Item -LiteralPath $env:RAG_SNAPSHOT -Destination (Join-Path $snapshotDir 'week1-demo.sql')
    Write-Host "Verified snapshot: $(Join-Path $snapshotDir 'week1-demo.sql')"
} finally {
    if ($server -and !$server.HasExited) {
        & $mysqlAdmin "--defaults-extra-file=$optionFile" --connect-timeout=2 shutdown 2>$null | Out-Null
        if (!$server.WaitForExit(10000)) { Stop-Process -Id $server.Id }
    }
    foreach ($name in $prior.Keys) { [Environment]::SetEnvironmentVariable($name, $prior[$name], 'Process') }
    # Keep data and logs for diagnosis, discard ephemeral credential files.
    foreach ($file in @($init, $optionFile)) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
    }
}
