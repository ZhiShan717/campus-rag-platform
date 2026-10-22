[CmdletBinding()]
param([switch]$Messaging)

. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-CampusDocker
$composeArguments = @(Get-CampusComposeArguments -Messaging:$Messaging)
& docker @composeArguments config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Compose validation failed.' }
$expected = @('mysql', 'redis', 'elasticsearch', 'minio', 'nacos')
if ($Messaging) { $expected += @('namesrv', 'broker') }
foreach ($service in $expected) {
    $id = & docker @composeArguments ps --quiet $service
    if ($LASTEXITCODE -ne 0 -or -not $id) { throw ('Service is not running: ' + $service) }
    # Inspect only health status: full docker inspect contains secret variables.
    $health = & docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $id
    if ($LASTEXITCODE -ne 0 -or $health -ne 'healthy') { throw ('Service is not healthy: ' + $service) }
    Write-Host ($service + ': healthy')
}

if ($Messaging) {
    try {
        # Run inside the broker so its advertised loopback address is reachable.
        # Bound the short-lived admin JVM independently of the broker heap.
        $registration = & docker @composeArguments exec --no-TTY -e 'JAVA_OPT_EXT=-Xms64m -Xmx128m -XX:MaxDirectMemorySize=64m' broker sh mqadmin clusterList -n namesrv:9876 2>&1
        if ($LASTEXITCODE -ne 0 -or (($registration -join "`n") -notmatch 'CampusDevCluster\s+campus-dev-broker\s+0\s+127\.0\.0\.1:10911\s+V5_3_1')) {
            throw 'Broker registration was not confirmed.'
        }
        Write-Host 'rocketmq: broker registration with namesrv verified (V5_3_1)'
    } catch { throw 'RocketMQ broker registration verification failed. Check the message-service logs.' }
}

# The bundled MinIO client authenticates without printing credentials or writing
# a client alias/configuration. No bucket or object is created by this check.
& docker @composeArguments exec --no-TTY minio /bin/sh -ec 'MC_HOST_campusdev="http://$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@127.0.0.1:9000" mc admin info campusdev >/dev/null 2>&1'
if ($LASTEXITCODE -ne 0) { throw 'MinIO authenticated API verification failed.' }
Write-Host 'minio: authenticated API verified'

$secrets = Read-CampusSecrets
try {
    $basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('elastic:' + $secrets.ELASTIC_PASSWORD))
    $headers = @{Authorization = 'Basic ' + $basic}
    $analyzed = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:9200/_analyze' -Headers $headers -ContentType 'application/json; charset=utf-8' -Body '{"analyzer":"ik_smart","text":"\u6821\u56ed\u77e5\u8bc6\u5e93"}' -TimeoutSec 15 -ErrorAction Stop -Verbose:$false -Debug:$false
    if (-not $analyzed.tokens -or $analyzed.tokens.Count -lt 1) { throw 'IK did not return tokens.' }
    Write-Host 'elasticsearch: matching IK analyzer verified'
    $login = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8848/nacos/v1/auth/login' -ContentType 'application/x-www-form-urlencoded' -Body @{username = 'nacos'; password = $secrets.NACOS_ADMIN_PASSWORD} -TimeoutSec 15 -ErrorAction Stop -Verbose:$false -Debug:$false
    if (-not $login.accessToken) { throw 'Nacos authentication failed.' }
    Write-Host 'nacos: generated administrator password verified'
} catch {
    throw 'Service authentication or IK verification failed. No credentials or response bodies were printed.'
}
