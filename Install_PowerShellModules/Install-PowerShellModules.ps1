<#PSScriptInfo
.VERSION 1.1.0
.GUID 893e2a7c-58b7-48c6-a287-8d86896a4c5a
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS Install O365 Azure Pester Module
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES
    1.0.0  Initial release
    1.1.0  Functions moved into module & module list moved to JSON file
#>

<#
    .SYNOPSIS
    Automates installation of PSGallery PowerShell modules specified in JSON file

    .DESCRIPTION
    Automatically elevates the PowerShell script and installs JSON specified PowerShell modules with the latest version.
    Includes upgrade from Pester v3 to Pester v5.
    Installs latest version of PowerShell 7

    .NOTES
    Script must run from an elevated command prompt (user should be prompted)
    Requires setting the execution to allow running local scripts if not already set
    Get-ExecutionPolicy is the result is "Undefined" -or "Restricted", run:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
#>

#Requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"

# 1.0.0 Start script, get start time
$startTime = (Get-Date).ToUniversalTime()

# 1.1.0 Auto-Elevate PowerShell script if not already
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $commandLine = '-Command ' + '"& {' + "$PSScriptRoot\Install-PowerShellModules.ps1" + '}"'
    Start-Process PowerShell.exe -Verb Runas -ArgumentList $commandLine
    exit 0
}

# 1.2.0 Install_PowerShellModules module
try { Import-Module "$PSScriptRoot\Install_PowerShellModules" }
catch { throw "Install_PowerShellModules module not found!" }

# 1.3.0 Import module install list from JSON file
try { $powerShellModulesList = Get-Content "$PSScriptRoot\PowerShellModulesList.json" | ConvertFrom-Json }
catch { Write-Error "PowerShellModulesList JSON file is not in the same folder as script" }

# 1.4.0 Set log file path
$global:logFilePath = "$env:TEMP\InstallPowerShellModules" + "_(" + $env:COMPUTERNAME + ").txt"
$separator = "===================================================================="

# 1.5.0 Get Modules to be installed or updated to the latest version
[string[]]$modules = $powerShellModulesList.modules
$moduleInstallResults = [System.Collections.ArrayList]::new()

# 1.6.0 Begin update log
Write-Log $separator
Write-Log "Install-PowerShellModules started at $startTime UTC" Cyan

# 2.0.0 Begin module installation

# 2.1.0 Always make sure that PSGallery is installed and trusted or all other module install operations will be problematic
Install-PowerShellGet

# 2.2.0 Install the latest version of specified modules if missing or outdated
$results = Install-PowerShellModule -ModuleList $modules
[void]$moduleInstallResults.AddRange($results)

# 2.3.0 Pester is a special case and requires different handling
if ($powerShellModulesList.pesterUpgrade -eq $true) {
    Remove-Pester3
    $pesterUpgradeResult = Install-PowerShellModule -ModuleList "Pester"
    [void]$moduleInstallResults.Add($pesterUpgradeResult)
}

# 3.0.0 Download and install/upgrade PowerShell 7
if ($powerShellModulesList.powershell7Install -eq $true) {
    $ps7InstallResult = Install-PowerShell7
    [void]$moduleInstallResults.Add($ps7InstallResult)
}

# 4.0.0 Display results
Write-Log "Modules install results:"
Write-Log $moduleInstallResults

# 4.1.0 Log script execution time
$scriptExecutionTime = ((Get-Date).ToUniversalTime()) - $startTime
Write-Log "Install-PowerShellModules took $($scriptExecutionTime.ToString("hh\:mm\:ss")) to complete."
Write-Log $separator
# 4.2.0 Display log file path
Write-Host "Log file for install located at: $global:logFilePath"
# 4.3.0 Leave output on screen for 10 seconds before closing the window
Start-Sleep 10
