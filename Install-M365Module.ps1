<#PSScriptInfo
.VERSION 1.0.0
.GUID 
.AUTHOR 
.COMPANYNAME 
.COPYRIGHT 
.TAGS O365 M365 Azure Pester Module
.LICENSEURI https://example.com/
.PROJECTURI https://example.com/
.RELEASENOTES
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Automates the installation of Microsoft M365 PowerShell module(s)

    .DESCRIPTION
    Automatically elevates the PowerShell script and installs specified Microsoft M365 and Azure PowerShell modules with the latest version.
    Also includes option to install Pester v5.

    .PARAMETER Options
    Allows for the selection of specific groups of modules. If no value is entered script defaults to 'All'

    .NOTES
    Script must run from an elevated command prompt (user should be prompted)
    Requires setting the execution to allow running local scripts if not already set
    Get-ExecutionPolicy is the result is "Undefined" -or "Restricted", run:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
#>

[CmdletBinding()]
param(
    [parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [ValidateSet("All", "Pester", "O365", "Azure", "Graph")]
    [string[]]$Options = "All"
)

# PowerShell 5.x required. The version of PowerShell included with Windows 10
#Requires -Version 5.0

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $cmdOptions = $Options -join ','
    $commandLine = '-Command ' + '"& {'  + "$PSScriptRoot\Install-M365Module.ps1" + " -Options $cmdOptions" + '}"'
    Start-Process PowerShell.exe -Verb Runas -ArgumentList $commandLine
    exit 0
}

$ErrorActionPreference = "SilentlyContinue"

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
            Write-Log "`nThe $module module is already installed with version $moduleVersion." Green
            $moduleInstallStatus = "Current"

        }
        else {
            if ($module -eq "Pester") {
                Remove-Pester3
            }
            Write-Log "`nThe $module module is either not installed or is an outdated version.`nInstalling current version."
            try {
                Install-Module -Name $module -MinimumVersion $moduleVersion -Force -AllowClobber -Confirm:$false
                $moduleInstallStatus = "Installed"
            }
            catch {
                $basicError = $Error[0]
                Write-Log "Module install failed.`n Error: $basicError" Red
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

    if (-not $logFileOnly) {
        # Log line output to the console
        $host.ui.RawUI.ForegroundColor = $Color
        Out-Host -InputObject $LogLine 
    }
}

# List of Modules to be installed or updated to the latest version
$allModules = @{
    "O365"   = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MicrosoftTeams",
        "Microsoft.Online.SharePoint.PowerShell",
        "AIPService",
        "PnP.PowerShell"
    )
    "Azure"  = @(
        "Az"
    )
    "Pester" = @(
        "Pester"
    )
    "Graph" = @(
        "Microsoft.Graph"
    )
}

$global:logFilePath = "$env:TEMP\InstallM365Module" + "_(" + $env:COMPUTERNAME + ").txt"
$startTime = (Get-Date).ToUniversalTime()
$separator = "========================================================================"
$moduleInstallResults = [System.Collections.ArrayList]::new()
$moduleInstallResults = @()

# Log start of Install-M365Module
Write-Log "`n$separator`nInstall-M365Module started at $startTime UTC with the following option: $Options"

if ($Options -contains "All") {
    $Options = @("O365", "Azure", "Pester", "Graph")
}

# Always make sure that PowerShell Get is installed and trusted or all other module install operations will be problematic
Install-PowerShellGet

# Install the latest version of specified modules if missing or outdated
foreach ($option in $Options) {
    $result = Install-PowerShellModule -ModuleList $($allModules.$option)
    $moduleInstallResults += $result
}

Write-Log "`nModules install results:"
Write-Log $moduleInstallResults

# Log end of Install-M365Module
$scriptExecutionTime = ((Get-Date).ToUniversalTime()) - $startTime
Write-Log "Install-M365Module took $($scriptExecutionTime.ToString("hh\:mm\:ss")) to complete.`n$separator"
Start-Sleep 5
