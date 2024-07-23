<#PSModuleInfo
.GUID 36097204-1266-47ed-b09e-6f23b7af3820
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.MANIFEST Install_PowerShellModules.psd1
.RELEASENOTES
    Change history located in Install_PowerShellModules.psd1
    (Import-PowerShellDataFile .\Install_PowerShellModules.psd1).PrivateData.PSData.ReleaseNotes
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
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

function Install-PowerShellGet {
    <#
    .SYNOPSIS
    Executes PowerShell commands required to install PowerShellGet (PSGallery)

    .NOTES 
    Source: https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.2
    #>

    # 2.1.1 Set TLS 1.2
    Write-Log "Setting TLS version to 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # 2.1.2 Install the latest NuGet provider
    Write-Log "Installing the latest version of the NuGet package provider"
    Install-PackageProvider -Name NuGet -Force -Confirm:$false

    # 2.1.3 Allow modules to be installed from PS Gallery without prompts
    Write-Log "Setting PSGallery installation policy to trusted"
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

    # 2.1.4 Install PowerShellGet
    Write-Log "Installing PowerShellGet"
    $result = Install-PowerShellModule -ModuleList PowerShellGet
}

function Install-PowerShellModule {
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

    # 2.2.1 Loop through each PowerShell module in the list
    foreach ($module in $ModuleList) {
        # 2.2.2 Check if the module is already installed
        $moduleVersion = (Find-Module -Name $module).Version
        $moduleInstalled = Get-InstalledModule -Name $module -MinimumVersion $moduleVersion -ErrorAction SilentlyContinue
        if ($moduleInstalled) {
            Write-Log "The $module module is already installed with version $moduleVersion." Green
            $moduleInstallStatus = "Current"

        }
        else {
            # 2.2.3 Install/update the specified module
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

        # 2.2.4 Collect the module install results
        $installResult = [PSCustomObject]@{
            "Module Name"    = $module
            "Module Version" = $moduleVersion
            "Result"         = $moduleInstallStatus
        }
        [void]$installResults.Add($installResult)
    }

    return $installResults
}

function Remove-Pester3 {
    <#
    .SYNOPSIS
    Remove Windows 10 built-in Pester v3 to enable upgrade to Pester v5

    .DESCRIPTION
    Upgrading Pester using Install-Module results in errors because of incompatibilities.
    This function removes Pester v3 so that Pester v5 can be installed

    .NOTES
    Remove & install commands from: https://pester-docs.netlify.app/docs/introduction/installation
    #>
    
    # 2.3.1 Check to see if any version of Pester v5 is already installed
    $v5PesterInstalled = Get-InstalledModule -Name Pester -MinimumVersion 5.0.0
    if ($null -eq $v5PesterInstalled) {
        # 2.3.2 Remove Pester v3 module files and reg keys
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

function Install-PowerShell7 {
    <#
    .SYNOPSIS
    Installs PowerShell 7

    .DESCRIPTION
    Calls Microsoft script that installs the PowerShell 7 MSI package in quiet mode

    .NOTES
    Script source: https://aka.ms/install-powershell.ps1
    #>

    # 3.0.1 Get currently installed version of PowerShell 7
    [version]$ps7Version = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\*" -Name "SemanticVersion"
    if ($null -ne $ps7Version) {
        # 3.0.2 Get the latest version of PowerShell 7
        $metadata = Invoke-RestMethod "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
        [version]$release = $metadata.ReleaseTag -replace '^v'
        # 3.0.3 Check if PowerShell version is current or not installed
        if ($ps7Version -lt $release) {
            Write-Log "Updating PowerShell 7 from $ps7Version to version $release"
            $installPS7 = $true
        }
        else {
            Write-Log "PowerShell 7 is up-to-date" Green
            $moduleInstallStatus = "Current"
            $installPS7 = $false
        }
    }
    else {
        Write-Log "PowerShell 7 not installed. Installing version $release"
        $installPS7 = $true
    }

    # 3.0.4 Install/update PowerShell 7
    if ($installPS7 -eq $true) {
        try {
            Invoke-Expression "& { $(Invoke-RestMethod -Uri "https://aka.ms/install-powershell.ps1") } -UseMSI -Quiet"
            $moduleInstallStatus = "Installed"
        }
        catch {
            $basicError = $Error[0]
            Write-Log "Module install failed. Error: $basicError" Red
            $moduleInstallStatus = "Failed"
        }
    }

    # 3.0.5 Collect PowerShell 7 install results
    $installResult = [PSCustomObject]@{
        "Module Name"    = "PowerShell 7"
        "Module Version" = $release.ToString()
        "Result"         = $moduleInstallStatus
    }

    return $installResult
}
