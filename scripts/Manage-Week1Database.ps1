[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Initialize','Backup','Restore')][string]$Action,
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,63}$')][string]$Database = 'campus_rag_week1',
    [string]$Server = '127.0.0.1',
    [ValidateRange(1,65535)][int]$Port = 3306,
    [string]$User = 'root',
    [Security.SecureString]$Password,
    [string]$File,
    [string]$MySqlBin = 'C:\Program Files\MySQL\MySQL Server 8.0\bin'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mysql = Join-Path $MySqlBin 'mysql.exe'
$dump = Join-Path $MySqlBin 'mysqldump.exe'
if (!(Test-Path -LiteralPath $mysql)) { throw "mysql.exe not found: $mysql" }
if ($Action -eq 'Restore' -and (!$File -or !(Test-Path -LiteralPath $File -PathType Leaf))) {
    throw 'Restore requires -File pointing to an existing SQL snapshot.'
}
if ($Action -eq 'Backup') {
    if (!$File) { throw 'Backup requires -File for a new snapshot.' }
    if (Test-Path -LiteralPath $File) { throw 'The backup file already exists; choose a new filename.' }
    $backupParent = Split-Path -Parent ([System.IO.Path]::GetFullPath($File))
    if (!(Test-Path -LiteralPath $backupParent)) { throw 'Create the backup directory first.' }
}
$secure = if ($Password) { $Password } else { Read-Host 'MySQL password (local account)' -AsSecureString }
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
$options = Join-Path ([System.IO.Path]::GetTempPath()) ('rag-client-' + [guid]::NewGuid().ToString('N') + '.cnf')
$temporaryDump = Join-Path ([System.IO.Path]::GetTempPath()) ('rag-dump-' + [guid]::NewGuid().ToString('N') + '.sql')
function Quote-Option([string]$Value) {
    if ($Value.Contains("`n") -or $Value.Contains("`r")) { throw 'Option values cannot contain newlines.' }
    return '"' + $Value.Replace('\','\\').Replace('"','\"') + '"'
}
$encodingBefore = $OutputEncoding
try {
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = $utf8
    $config = "[client]`nhost=$(Quote-Option $Server)`nport=$Port`nuser=$(Quote-Option $User)`npassword=$(Quote-Option $plain)`ndefault-character-set=utf8mb4`n"
    [System.IO.File]::WriteAllText($options, $config, $utf8)
    $plain = $null
    if ($Action -in @('Initialize','Restore')) {
        # CREATE without IF NOT EXISTS refuses to overwrite an existing database.
        & $mysql "--defaults-extra-file=$options" "--execute=CREATE DATABASE $Database CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci"
        if ($LASTEXITCODE -ne 0) { throw 'Database creation failed. An existing database will not be reused.' }
        $inputs = if ($Action -eq 'Initialize') {
            @((Join-Path $root 'project/database/mysql/migrations/V001__initial.sql'),
              (Join-Path $root 'project/database/mysql/seeds/V001__demo.sql'))
        } else { @($File) }
        foreach ($inputFile in $inputs) {
            Get-Content -LiteralPath $inputFile -Raw -Encoding UTF8 | & $mysql "--defaults-extra-file=$options" "--database=$Database"
            if ($LASTEXITCODE -ne 0) { throw "Import failed: $inputFile. The new database may be partial; inspect it before retrying." }
        }
    } else {
        & $dump "--defaults-extra-file=$options" --single-transaction --no-tablespaces --set-gtid-purged=OFF "--result-file=$temporaryDump" $Database
        if ($LASTEXITCODE -ne 0) { throw 'Backup failed.' }
        Copy-Item -LiteralPath $temporaryDump -Destination $File
    }
    Write-Host "$Action completed: $Database"
} finally {
    $plain = $null
    $OutputEncoding = $encodingBefore
    foreach ($path in @($options,$temporaryDump)) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
    }
}
