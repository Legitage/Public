<#PSScriptInfo
.VERSION 1.0.0
.GUID 893e2a7c-58b7-48c6-a287-8d86896a4c5a
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS O365 Azure Pester Module
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Automates installation of PowerShell modules specified in JSON file

    .DESCRIPTION
    Automatically elevates the PowerShell script and installs JSON specified PowerShell modules with the latest version.
    Also includes option to install Pester v5.

    .NOTES
    Script must run from an elevated command prompt (user should be prompted)
    Requires setting the execution to allow running local scripts if not already set
    Get-ExecutionPolicy is the result is "Undefined" -or "Restricted", run:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
#>

#Requires -Version 5.2
$ErrorActionPreference = "SilentlyContinue"

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $commandLine = '-Command ' + '"& {'  + "$PSScriptRoot\Install-PowerShellModules.ps1" + '}"'
    Start-Process PowerShell.exe -Verb Runas -ArgumentList $commandLine
    exit 0
}

Function Install-PowerShellModule {
    <#
    .SYNOPSIS
    Installs the latest version of specified PowerShell module(s)

    .DESCRIPTION
    Finds the latest version of a module and checks if it is already installed.
    If not, the latest version of the module is installed. 

    .PARAMETER ModuleList
    List of PowerShell modules to install
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string[]]$ModuleList
    )

    $installResults = [System.Collections.ArrayList]::new()

    foreach ($module in $ModuleList) {
        $moduleVersion = (Find-Module -Name $module).Version
        $moduleInstalled = Get-InstalledModule -Name $module -MinimumVersion $moduleVersion -ErrorAction SilentlyContinue
        if ($moduleInstalled) {
            Write-Log "The $module module is already installed with version $moduleVersion." Green
            $moduleInstallStatus = "Current"

        }
        else {
            # Pester is a special case and requires different handling
            if ($module -eq "Pester") {
                Remove-Pester3
            }
            Write-Log "The $module module is either not installed or is an outdated version. Installing current version."
            try {
                Install-Module -Name $module -MinimumVersion $moduleVersion -Force -AllowClobber -Confirm:$false
                $moduleInstallStatus = "Installed"
            }
            catch {
                $basicError = $Error[0]
                Write-Log "Module install failed. Error: $basicError" Red
                $moduleInstallStatus = "Failed"
            }
        }

        $installResult = [PSCustomObject]@{
            "Module Name"    = $module
            "Module Version" = $moduleVersion
            "Result"         = $moduleInstallStatus
        }
        [void]$installResults.Add($installResult)
    }

    return $installResults
}

Function Remove-Pester3 {
    <#
    .SYNOPSIS
    Remove Windows 10 built-in Pester v3 to enable upgrade to Pester v5

    .DESCRIPTION
    Upgrading Pester using Install-Module results in errors because of incompatibilities.
    This function removes Pester v3 so that Pester v5 can be installed

    .NOTES
    Remove & install commands from: https://pester-docs.netlify.app/docs/introduction/installation
    #>
    
    # Check to see if any version of Pester v5 is already installed
    $v5PesterInstalled = Get-InstalledModule -Name Pester -MinimumVersion 5.0.0
    if ($null -eq $v5PesterInstalled) {
        Write-Log "Removing Pester v3"
        $pester3ModuleDir = "C:\Program Files\WindowsPowerShell\Modules\Pester"
        takeown /F $pester3ModuleDir /A /R
        icacls $pester3ModuleDir /reset
        icacls $pester3ModuleDir /grant "*S-1-5-32-544:F" /inheritance:d /T
        Remove-Item -Path $pester3ModuleDir -Recurse -Force -Confirm:$false
        Start-Sleep 1
    }
    else {
        Write-Log "Pester v5 is already installed!" Green
    }
}

Function Install-PowerShellGet {
    <#
    .SYNOPSIS
    Executes PowerShell commands required to install PowerShellGet (PSGallery)

    .NOTES 
    Source: https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.2
    #>

    # Set TLS 1.2
    Write-Log "Setting TLS version to 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Allow modules to be installed from PS Gallery without all the prompts
    Write-Log "Setting PSGallery installation policy to trusted"
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

    # Install the latest NuGet provider
    Write-Log "Installing the latest version of the NuGet package provider"
    Install-PackageProvider -Name NuGet -Force -Confirm:$false

    $result = Install-PowerShellModule -ModuleList PowerShellGet
}

Function Write-Log {
    <#
    .SYNOPSIS
    Enables writing the same output to a file and to the console
    #>

    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        $LogLine,
        [parameter(Position = 1)]
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )

    # Log line output to a file
    Out-File -InputObject $LogLine -FilePath $logFilePath -Encoding ascii -Width 400 -Append
    
    # Log line output to the console
    $host.ui.RawUI.ForegroundColor = $Color
    Out-Host -InputObject $LogLine 
    
}

# Get Modules to be installed or updated to the latest version
[string[]]$moduleList = (Get-Content "$PSScriptRoot\PowerShellModulesList.json" | ConvertFrom-Json).modules


$global:logFilePath = "$env:TEMP\InstallPowerShellModules" + "_(" + $env:COMPUTERNAME + ").txt"
$startTime = (Get-Date).ToUniversalTime()
$separator = "========================================================================"
$moduleInstallResults = [System.Collections.ArrayList]::new()
$moduleInstallResults = @()

# Log start of Install-PowerShellModules
Write-Log $separator
Write-Log "Install-PowerShellModules started at $startTime UTC"

# Always make sure that PowerShell Get is installed and trusted or all other module install operations will be problematic
Install-PowerShellGet

# Install the latest version of specified modules if missing or outdated
$result = Install-PowerShellModule -ModuleList $moduleList
$moduleInstallResults += $result


Write-Log "Modules install results:"
Write-Log $moduleInstallResults

# Log end of Install-PowerShellModules
$scriptExecutionTime = ((Get-Date).ToUniversalTime()) - $startTime
Write-Log "Install-PowerShellModules took $($scriptExecutionTime.ToString("hh\:mm\:ss")) to complete."
Write-Log $separator
# Leave output on screen for 10 seconds before closing the window
Start-Sleep 10
