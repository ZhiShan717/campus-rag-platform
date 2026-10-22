@echo off
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-OwnerEnvironment.ps1"
if errorlevel 1 echo Startup failed. See the message above.
pause
