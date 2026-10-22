[CmdletBinding()]
param(
    [switch]$Accessible
)

$ErrorActionPreference = 'Stop'
$desktopPath = 'D:\github\GitHubDesktop\GitHubDesktop.exe'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $workspaceRoot '.setup\logs'
$logPath = Join-Path $logDirectory 'github-desktop-launch.log'

function ConvertTo-ProxyAddress {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $candidate = $Value.Trim()
    if ($candidate -notmatch '^[A-Za-z][A-Za-z0-9+.-]*://') {
        $candidate = 'http://' + $candidate
    }
    $parsed = $null
    if (-not [Uri]::TryCreate($candidate, [UriKind]::Absolute, [ref]$parsed) -or
        $parsed.Scheme -notin @('http', 'https', 'socks4', 'socks5') -or
        [string]::IsNullOrWhiteSpace($parsed.Host) -or
        $parsed.Port -lt 1 -or $parsed.Port -gt 65535 -or
        -not [string]::IsNullOrEmpty($parsed.UserInfo) -or
        $parsed.AbsolutePath -ne '/' -or
        -not [string]::IsNullOrEmpty($parsed.Query) -or
        -not [string]::IsNullOrEmpty($parsed.Fragment)) {
        throw '系统代理地址无法安全识别。请在 Windows 代理设置中检查服务器和端口。'
    }
    # Restrict command-line arguments to a validated URI, with no credentials or quotes.
    if ($parsed.Host -notmatch '^[A-Za-z0-9.:-]+$') {
        throw '系统代理服务器名称无效。请检查 Windows 代理设置。'
    }
    return $parsed.GetLeftPart([UriPartial]::Authority)
}

try {
    if (-not (Test-Path -LiteralPath $desktopPath -PathType Leaf)) {
        throw '找不到 D 盘中的 GitHub Desktop，请检查应用安装目录。'
    }

    $settings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $proxyAddress = $null
    if ($settings.ProxyEnable -eq 1) {
        $configuredProxy = [string]$settings.ProxyServer
        if ([string]::IsNullOrWhiteSpace($configuredProxy)) {
            throw 'Windows 已启用代理，但代理地址为空。请先检查系统代理设置。'
        }
        if ($configuredProxy.Contains('=')) {
            # WinINET can store separate HTTP and HTTPS entries. GitHub uses HTTPS.
            $proxyEntries = @{}
            foreach ($entry in $configuredProxy.Split(';')) {
                $pair = $entry -split '=', 2
                if ($pair.Count -eq 2) {
                    $proxyEntries[$pair[0].Trim().ToLowerInvariant()] = $pair[1].Trim()
                }
            }
            if ($proxyEntries.ContainsKey('https')) {
                $proxyAddress = ConvertTo-ProxyAddress $proxyEntries['https']
            } elseif ($proxyEntries.ContainsKey('http')) {
                $proxyAddress = ConvertTo-ProxyAddress $proxyEntries['http']
            } elseif ($proxyEntries.ContainsKey('socks')) {
                $proxyAddress = ConvertTo-ProxyAddress ('socks5://' + $proxyEntries['socks'])
            } else {
                throw '系统代理未包含可用于 GitHub 的 HTTP、HTTPS 或 SOCKS 配置。'
            }
        } else {
            $proxyAddress = ConvertTo-ProxyAddress $configuredProxy
        }
    }

    $processInfo = New-Object Diagnostics.ProcessStartInfo
    $processInfo.FileName = $desktopPath
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.WorkingDirectory = Split-Path -Parent $desktopPath
    $arguments = New-Object 'System.Collections.Generic.List[string]'

    if ($null -ne $proxyAddress) {
        # These changes belong only to the child process. Windows environment names
        # are case-insensitive, so the uppercase names also cover lowercase consumers.
        foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY')) {
            $processInfo.EnvironmentVariables[$name] = $proxyAddress
        }
        $arguments.Add('--proxy-server="' + $proxyAddress + '"')
    }

    $noProxy = New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in ([string]$processInfo.EnvironmentVariables['NO_PROXY']).Split(',')) {
        if (-not [string]::IsNullOrWhiteSpace($entry)) { $noProxy.Add($entry.Trim()) }
    }
    foreach ($localHostName in @('localhost', '127.0.0.1', '::1')) {
        if (-not $noProxy.Contains($localHostName)) { $noProxy.Add($localHostName) }
    }
    $processInfo.EnvironmentVariables['NO_PROXY'] = $noProxy -join ','
    if ($Accessible) { $arguments.Add('--force-renderer-accessibility') }
    $processInfo.Arguments = $arguments -join ' '

    # An already-running Desktop instance will retain its own environment and focus
    # normally. This launcher does not stop the application or change global settings.
    [void][Diagnostics.Process]::Start($processInfo)
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $proxyStatus = if ($null -ne $proxyAddress) { '已传递当前 Windows 代理' } else { 'Windows 手动代理未启用' }
    ('[' + [DateTime]::Now.ToString('s') + '] GitHub Desktop 启动请求已发送；' + $proxyStatus + '。') |
        Add-Content -LiteralPath $logPath -Encoding UTF8
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [void][Windows.Forms.MessageBox]::Show(
        ('GitHub Desktop 启动失败。' + [Environment]::NewLine + $_.Exception.Message),
        'GitHub Desktop',
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}
