[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$envPath = Join-Path $PSScriptRoot '.env'
$temporaryPath = Join-Path $PSScriptRoot '.env.new'

function New-RandomBytes([int]$Length) {
    $bytes = New-Object byte[] $Length
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    return ,$bytes
}

function New-RandomPassword {
    return ([BitConverter]::ToString((New-RandomBytes 32))).Replace('-', '').ToLowerInvariant()
}

function Protect-SecretFile([string]$Path) {
    # Grant only the invoking Windows user, SYSTEM, and local administrators.
    # Run under the intended real desktop user, not an unrelated service account.
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $currentAcl = Get-Acl -LiteralPath $Path
    $expectedSids = @($identity.User.Value, 'S-1-5-18', 'S-1-5-32-544')
    $currentRules = @($currentAcl.Access)
    $matchesExpectedAcl = $currentAcl.AreAccessRulesProtected -and $currentRules.Count -eq 3
    foreach ($existingRule in $currentRules) {
        $ruleSid = $existingRule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
        if ($ruleSid -notin $expectedSids -or $existingRule.IsInherited -or $existingRule.AccessControlType -ne 'Allow' -or $existingRule.FileSystemRights -ne [System.Security.AccessControl.FileSystemRights]::FullControl) {
            $matchesExpectedAcl = $false
        }
    }
    # Already-correct ACLs need no write. Rewriting them can require extra
    # security privileges under managed Windows execution contexts.
    if ($matchesExpectedAcl) { return }
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner($identity.User)
    $principals = @($identity.User, (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18'), (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'))
    foreach ($principal in $principals) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($principal, 'FullControl', 'Allow')
        [void]$acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
}

$requiredKeys = @('MYSQL_ROOT_PASSWORD', 'MYSQL_PASSWORD', 'REDIS_PASSWORD', 'ELASTIC_PASSWORD', 'MINIO_ROOT_USER', 'MINIO_ROOT_PASSWORD', 'NACOS_AUTH_TOKEN', 'NACOS_AUTH_IDENTITY_KEY', 'NACOS_AUTH_IDENTITY_VALUE', 'NACOS_ADMIN_PASSWORD')
if (Test-Path -LiteralPath $envPath) {
    $lines = [System.IO.File]::ReadAllLines($envPath)
    foreach ($key in $requiredKeys) {
        if (-not ($lines | Where-Object { $_ -match ('^' + [regex]::Escape($key) + '=.+$') })) {
            throw 'The existing .env is incomplete. Restore the original complete file; credentials were not changed.'
        }
    }
    Protect-SecretFile $envPath
    Write-Host 'Existing credentials preserved; .env access permissions verified.'
    exit 0
}

if (Test-Path -LiteralPath $temporaryPath) {
    throw 'A previous .env.new exists. Review it locally before retrying; no secrets were overwritten.'
}

try {
    # No credentials are written until the empty temporary file is protected.
    [void](New-Item -ItemType File -Path $temporaryPath)
    Protect-SecretFile $temporaryPath
    $values = [ordered]@{
        MYSQL_ROOT_PASSWORD = New-RandomPassword
        MYSQL_PASSWORD = New-RandomPassword
        REDIS_PASSWORD = New-RandomPassword
        ELASTIC_PASSWORD = New-RandomPassword
        MINIO_ROOT_USER = 'campusdev_' + ([BitConverter]::ToString((New-RandomBytes 8))).Replace('-', '').ToLowerInvariant()
        MINIO_ROOT_PASSWORD = New-RandomPassword
        NACOS_AUTH_TOKEN = [Convert]::ToBase64String((New-RandomBytes 48))
        NACOS_AUTH_IDENTITY_KEY = 'campusdev_' + ([BitConverter]::ToString((New-RandomBytes 8))).Replace('-', '').ToLowerInvariant()
        NACOS_AUTH_IDENTITY_VALUE = New-RandomPassword
        NACOS_ADMIN_PASSWORD = New-RandomPassword
    }
    $content = @('# Local development credentials. Do not commit or publish this file.', '# Keep this file with the persisted volumes; changing it does not rotate stored passwords.')
    foreach ($key in $values.Keys) { $content += $key + '=' + $values[$key] }
    [System.IO.File]::WriteAllLines($temporaryPath, $content, (New-Object System.Text.UTF8Encoding $false))
    Move-Item -LiteralPath $temporaryPath -Destination $envPath
    Write-Host 'Created random local credentials in the protected .env file. Values were not printed.'
} catch {
    # Leave any protected temporary file intact for local recovery.
    throw 'Credential initialization failed. Inspect local file permissions; no secret values were printed.'
}
