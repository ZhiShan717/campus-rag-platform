@echo off
title Campus RAG Development
cd /d "%~dp0.."
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -File "%~dp0Enter-DevEnvironment.ps1"
