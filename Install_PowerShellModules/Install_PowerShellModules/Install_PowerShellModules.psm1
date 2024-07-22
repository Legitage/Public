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

    foreach ($module in $ModuleList) {
        $moduleVersion = (Find-Module -Name $module).Version
        $moduleInstalled = Get-InstalledModule -Name $module -MinimumVersion $moduleVersion -ErrorAction SilentlyContinue
        if ($moduleInstalled) {
            Write-Log "The $module module is already installed with version $moduleVersion." Green
            $moduleInstallStatus = "Current"

        }
        else {
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

function Install-PowerShell7 {
    <#
    .SYNOPSIS
    R

    .DESCRIPTION
    U

    .NOTES
    
    #>
    [version]$ps7Version = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\*" -Name "SemanticVersion"
    if ($null -ne $ps7Version) {
        $metadata = Invoke-RestMethod "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
        [version]$release = $metadata.ReleaseTag -replace '^v'
        if ($ps7Version -lt $release) {
            Write-Log "Updating PowerShell 7 from $ps7Version to version $release"
            Invoke-Expression "& { $(Invoke-RestMethod -Uri "https://aka.ms/install-powershell.ps1") } -UseMSI"
        }
        else{
            Write-Log "PowerShell 7 is up-to-date" Green
        }
    }
    else {
        Write-Log "PowerShell 7 not installed. Installing version $release"
        Invoke-Expression "& { $(Invoke-RestMethod -Uri "https://aka.ms/install-powershell.ps1") } -UseMSI"
    }
}
