@echo off

:: Launches Install-PowerShellModules script with double-click or scheduled task
PowerShell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -Command "& {.\Install-PowerShellModules.ps1}"

exit /b 0