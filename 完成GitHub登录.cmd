@echo off
start "" /b "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0dev-environment\Complete-GitHubDesktopSignIn.ps1"
exit /b
