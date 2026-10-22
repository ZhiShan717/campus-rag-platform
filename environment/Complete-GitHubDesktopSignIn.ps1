[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:friendlyFailure = '请先从 GitHub Desktop 点击 Sign in，在微软 Edge 中完成 GitHub 官方网页的本人授权，再运行“完成GitHub登录”。'

function Show-SignInMessage {
    param([string]$Message, [switch]$IsError)
    $icon = [System.Windows.Forms.MessageBoxIcon]::Information
    if ($IsError) { $icon = [System.Windows.Forms.MessageBoxIcon]::Warning }
    [void][System.Windows.Forms.MessageBox]::Show(
        $Message, 'GitHub Desktop 登录', [System.Windows.Forms.MessageBoxButtons]::OK, $icon
    )
}

function Test-TrustedProtocolCommand {
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return $false }
    # Accept only the installed Desktop executable and its exact protocol arguments.
    $pattern = '\A"(?<exe>D:\\github\\GitHubDesktop\\(?:app-[0-9][A-Za-z0-9._-]*\\)?GitHubDesktop\.exe)"\s+--protocol-launcher\s+"%1"\s*\z'
    $match = [regex]::Match($Command, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { return $false }
    $executablePath = $match.Groups['exe'].Value
    if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) { return $false }
    $item = Get-Item -LiteralPath $executablePath
    while ($null -ne $item -and $item.FullName -ne 'D:\') {
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
        if ($item -is [System.IO.FileInfo]) { $item = $item.Directory } else { $item = $item.Parent }
    }
    return $true
}

function Assert-TrustedProtocolRegistration {
    $scheme = 'x-github-desktop-auth'
    $schemePath = 'Registry::HKEY_CLASSES_ROOT\' + $scheme
    $schemeKey = Get-Item -LiteralPath $schemePath
    if ($null -eq $schemeKey.GetValue('URL Protocol', $null)) { throw 'Untrusted protocol registration.' }
    $commandKey = Get-Item -LiteralPath ($schemePath + '\shell\open\command')
    if (-not (Test-TrustedProtocolCommand ([string]$commandKey.GetValue('')))) { throw 'Untrusted protocol handler.' }
    # A per-user association, if present, must resolve to the trusted program too.
    $choicePath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\' + $scheme + '\UserChoice'
    if (Test-Path -LiteralPath $choicePath) {
        $choiceKey = Get-Item -LiteralPath $choicePath
        $programId = [string]$choiceKey.GetValue('ProgId', '')
        if ([string]::IsNullOrWhiteSpace($programId) -or $programId -notmatch '\A[A-Za-z0-9._-]+\z') {
            throw 'Untrusted protocol association.'
        }
        $chosenCommandKey = Get-Item -LiteralPath ('Registry::HKEY_CLASSES_ROOT\' + $programId + '\shell\open\command')
        if (-not (Test-TrustedProtocolCommand ([string]$chosenCommandKey.GetValue('')))) {
            throw 'Untrusted protocol association handler.'
        }
    }
}

function Test-OfficialAuthorizationAddress {
    param([string]$Address)
    if ([string]::IsNullOrWhiteSpace($Address)) { return $false }
    $candidate = $Address.Trim()
    # Edge may omit the HTTPS prefix in its native address bar.
    if ($candidate -match '\Agithub\.com/') { $candidate = 'https://' + $candidate }
    $parsed = $null
    if (-not [Uri]::TryCreate($candidate, [UriKind]::Absolute, [ref]$parsed)) { return $false }
    return ($parsed.Scheme -eq 'https' -and $parsed.DnsSafeHost -eq 'github.com' -and
        $parsed.IsDefaultPort -and [string]::IsNullOrEmpty($parsed.UserInfo) -and
        $parsed.AbsolutePath -eq '/login/oauth/authorize' -and [string]::IsNullOrEmpty($parsed.Fragment))
}

function Test-DesktopOAuthCallback {
    param([string]$Callback)
    if ([string]::IsNullOrWhiteSpace($Callback) -or $Callback.Length -gt 8192) { return $false }
    # Never pass raw quotes, whitespace or invalid escapes to Windows protocol handling.
    if ($Callback -match '[\s"''<>]' -or $Callback -match '%(?![0-9a-fA-F]{2})') { return $false }
    if ($Callback -notmatch '\Ax-github-desktop-auth://oauth/?\?') { return $false }
    $parsed = $null
    if (-not [Uri]::TryCreate($Callback, [UriKind]::Absolute, [ref]$parsed)) { return $false }
    if ($parsed.Scheme -ne 'x-github-desktop-auth' -or $parsed.Host -ne 'oauth' -or
        -not $parsed.IsDefaultPort -or -not [string]::IsNullOrEmpty($parsed.UserInfo) -or
        $parsed.AbsolutePath -notin @('', '/') -or -not [string]::IsNullOrEmpty($parsed.Fragment)) { return $false }
    $pairs = @($parsed.Query.TrimStart('?').Split('&'))
    if ($pairs.Count -ne 2) { return $false }
    $values = @{}
    foreach ($pair in $pairs) {
        $parts = $pair -split '=', 2
        if ($parts.Count -ne 2 -or $parts[0] -notin @('code', 'state') -or $values.ContainsKey($parts[0])) {
            return $false
        }
        $value = [Uri]::UnescapeDataString($parts[1])
        if ([string]::IsNullOrWhiteSpace($value) -or $value.Length -gt 4096 -or
            $value -notmatch '\A[A-Za-z0-9._~+/=-]+\z') { return $false }
        $values[$parts[0]] = $true
    }
    return ($values.ContainsKey('code') -and $values.ContainsKey('state'))
}

function Test-NativeAddressControl {
    param(
        [System.Windows.Automation.AutomationElement]$Element,
        [System.Windows.Automation.AutomationElement]$Window
    )
    $names = @('Address and search bar', 'Address bar', 'Search or enter web address',
        '地址和搜索栏', '地址和搜索列', '地址和搜尋列', '搜尋或輸入網址')
    if ($Element.Current.AutomationId -ne 'addressEditBox' -and $Element.Current.Name -notin $names) { return $false }
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $ancestor = $Element
    for ($depth = 0; $depth -lt 40 -and $null -ne $ancestor; $depth++) {
        # Web inputs must never be mistaken for the browser's own address bar.
        if ($ancestor.Current.ControlType -eq [System.Windows.Automation.ControlType]::Document) { return $false }
        if ([System.Windows.Automation.Automation]::Compare($ancestor, $Window)) { return $true }
        $ancestor = $walker.GetParent($ancestor)
    }
    return $false
}

function Get-VerifiedAddressControl {
    param([System.Windows.Automation.AutomationElement]$Window)
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Edit
    )
    $edits = $Window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
    foreach ($edit in $edits) {
        if (-not (Test-NativeAddressControl -Element $edit -Window $Window)) { continue }
        $valuePattern = $null
        if ($edit.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$valuePattern) -and
            (Test-OfficialAuthorizationAddress ([string]$valuePattern.Current.Value))) { return $edit }
    }
    return $null
}

$callbackToOpen = $null
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $script:friendlyFailure = 'GitHub Desktop 的登录回调注册未通过检查。请先使用本文件夹中的 GitHub Desktop 入口启动应用，再重试；本脚本不会更改系统注册或代理设置。'
    Assert-TrustedProtocolRegistration

    $script:friendlyFailure = '未找到微软 Edge 中已授权的 GitHub 官方页面。请从 GitHub Desktop 点击 Sign in，在 Edge 中亲自完成官方授权，保留显示“this setup page”的结果页，再运行“完成GitHub登录”。'
    $edgeProcessIds = @{}
    foreach ($edgeProcess in @(Get-Process -Name msedge -ErrorAction SilentlyContinue)) {
        $edgeProcessIds[$edgeProcess.Id] = $true
    }
    if ($edgeProcessIds.Count -eq 0) { throw 'No Edge window.' }
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Window
    )
    $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Children, $condition
    )
    foreach ($window in $windows) {
        if (-not $edgeProcessIds.ContainsKey($window.Current.ProcessId)) { continue }
        try {
            $addressControl = Get-VerifiedAddressControl -Window $window
            if ($null -eq $addressControl) { continue }
            $typeCondition = New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
                [System.Windows.Automation.ControlType]::Hyperlink
            )
            $nameCondition = New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::NameProperty, 'this setup page'
            )
            $linkCondition = New-Object System.Windows.Automation.AndCondition($typeCondition, $nameCondition)
            $links = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $linkCondition)
            foreach ($link in $links) {
                $linkPattern = $null
                if (-not $link.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$linkPattern)) { continue }
                $candidateCallback = [string]$linkPattern.Current.Value
                if (-not (Test-DesktopOAuthCallback $candidateCallback)) { $candidateCallback = $null; continue }
                # Recheck the address immediately before accepting a callback.
                $addressPattern = $null
                if ($addressControl.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$addressPattern) -and
                    (Test-OfficialAuthorizationAddress ([string]$addressPattern.Current.Value))) {
                    $callbackToOpen = $candidateCallback
                    break
                }
                $candidateCallback = $null
            }
        } catch {
            # Tabs can close during inspection. Never display the raw exception.
        }
        if ($null -ne $callbackToOpen) { break }
    }
    if ($null -eq $callbackToOpen) { throw 'No authorized callback.' }
    $script:friendlyFailure = '无法将官方授权结果交回 GitHub Desktop。请先启动本文件夹中的 GitHub Desktop，再运行“完成GitHub登录”。'
    Assert-TrustedProtocolRegistration
    # The registered handler receives only the official OAuth result, never a CLI token or PAT.
    Start-Process -FilePath $callbackToOpen -WindowStyle Hidden -ErrorAction Stop
    $callbackToOpen = $null
    $candidateCallback = $null
    Show-SignInMessage -Message ('已将 GitHub 官方授权结果交回 GitHub Desktop。' + [Environment]::NewLine + '请在 GitHub Desktop 中确认账号是否已登录。')
} catch {
    # Callback queries and exception details must never reach the UI or a log.
    try { Show-SignInMessage -Message $script:friendlyFailure -IsError } catch {}
    exit 1
} finally {
    $callbackToOpen = $null
    $candidateCallback = $null
}
