[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'Common.ps1')
& (Join-Path $PSScriptRoot 'Initialize-Environment.ps1')
$path = Join-Path $PSScriptRoot '.env.application'
$temporaryPath = $path + '.new'
if (Test-Path -LiteralPath $path) {
    Write-Host 'Existing application connection settings preserved. No keys were rotated.'
    return
}
if (Test-Path -LiteralPath $temporaryPath) {
    throw 'An unfinished .env.application.new exists. Review it before retrying.'
}

function New-CampusApplicationKey {
    $bytes = New-Object byte[] 48
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $random.GetBytes($bytes) } finally { $random.Dispose() }
    return [Convert]::ToBase64String($bytes)
}

$secrets = Read-CampusSecrets
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$mysqlPort = if ($secrets.ContainsKey('MYSQL_PORT')) { $secrets.MYSQL_PORT } else { '13306' }
$settings = [ordered]@{
    DB_HOST = '127.0.0.1'
    DB_PORT = $mysqlPort
    DB_NAME = 'campus_rag'
    DB_USERNAME = 'campus_dev'
    DB_PASSWORD = $secrets.MYSQL_PASSWORD
    REDIS_HOST = '127.0.0.1'
    REDIS_PORT = '6379'
    REDIS_PASSWORD = $secrets.REDIS_PASSWORD
    ELASTICSEARCH_URL = 'http://127.0.0.1:9200'
    ELASTICSEARCH_USERNAME = 'elastic'
    ELASTICSEARCH_PASSWORD = $secrets.ELASTIC_PASSWORD
    MINIO_ENDPOINT = 'http://127.0.0.1:9000'
    MINIO_ACCESS_KEY = $secrets.MINIO_ROOT_USER
    MINIO_SECRET_KEY = $secrets.MINIO_ROOT_PASSWORD
    NACOS_SERVER_ADDR = '127.0.0.1:8848'
    NACOS_USERNAME = 'nacos'
    NACOS_PASSWORD = $secrets.NACOS_ADMIN_PASSWORD
    ROCKETMQ_NAMESRV_ADDR = '127.0.0.1:9876'
    OLLAMA_BASE_URL = 'http://127.0.0.1:11434'
    OLLAMA_MODEL = 'qwen3:1.7b'
    OLLAMA_KEEP_ALIVE = '0'
    OLLAMA_NUM_CTX = '2048'
    EMBEDDING_MODEL_PATH = (Join-Path $workspaceRoot '.local\models\bge-large-zh-v1.5').Replace('\', '/')
    EMBEDDING_DIMENSIONS = '1024'
    RERANKER_MODEL_PATH = (Join-Path $workspaceRoot '.local\models\bge-reranker-base').Replace('\', '/')
    APP_SECRET = New-CampusApplicationKey
    JWT_SECRET = New-CampusApplicationKey
}

# Protect the empty file before writing any value. Reuse the infrastructure
# credential ACL, which grants only this user, SYSTEM, and administrators.
[void](New-Item -ItemType File -Path $temporaryPath)
Set-Acl -LiteralPath $temporaryPath -AclObject (Get-Acl -LiteralPath (Join-Path $PSScriptRoot '.env'))
$content = @(
    '# Local connection settings for future application code. Never commit this file.',
    '# Map these names to the actual project configuration when the application exists.',
    '# Application URLs and routes are intentionally left to the real application.',
    '# Ollama callers must pass keep_alive=0 and options.num_ctx=2048 explicitly.'
)
foreach ($entry in $settings.GetEnumerator()) { $content += $entry.Key + '=' + $entry.Value }
[IO.File]::WriteAllLines($temporaryPath, $content, [Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $temporaryPath -Destination $path
Write-Host 'Created protected application connection settings and independent random APP/JWT keys. No values were printed.'
