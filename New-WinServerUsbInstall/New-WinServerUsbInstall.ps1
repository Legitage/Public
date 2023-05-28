<#PSScriptInfo
.VERSION 1.0.0
.GUID ff58f7fd-991c-42f7-b210-18239c8256dc
.AUTHOR Chad Armitage
.COMPANYNAME
.COPYRIGHT Chad Armitage
.TAGS Create Windows Server USB Bootable ISO Image
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES
    Change history located in README.md
#>

<#
    .SYNOPSIS
    Creates a USB drive for Windows Server installation

    .DESCRIPTION
    Copies install files from ISO Windows Server 2016, 2019, or 2022 server image
    and creates a UEFI or BIOS bootable USB drive
    
    .PARAMETER WindowsServerISO
    Path to the Windows Server 2022 ISO. Example: "C:\Temp\WindowsServer2022.iso"

    .PARAMETER BootType
    Option to specify UEFI GPT or legacy BIOS MBR (GPT is the default)

    .NOTES
    Script must run from an elevated command prompt
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
    [ValidateScript({ if ( -Not ($_ | Test-Path)) { throw "File does not exist" } return $true })]
    [System.IO.FileInfo]$WindowsServerISO,

    [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
    [ValidateSet("GPT", "MBR")] 
    [string]$BootType = "GPT"
)

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# Check for elevated PowerShell Window
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "`nScript must be run from an elevated command prompt.`n" -BackgroundColor Black -ForegroundColor Red
    exit 1
}

Function Copy-FolderItem {
    <#
    .SYNOPSIS
    Copies all the items from one folder/drive to another
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
        [string]$SourceFolder,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
        [string]$DestinationFolder
    )
    # Check for folder existence
    if (((Test-Path -Path $SourceFolder) -eq $false) -or ((Test-Path -Path $DestinationFolder) -eq $false)) {
        Write-Error "`nEither the source folder or the destination folder is not accessible!"
    }

    [string[]]$sourceItems = (Get-ChildItem -Path $SourceFolder -Force -ErrorAction SilentlyContinue).FullName
    foreach ($sourceItem in $sourceItems) {
        # Invoke native Windows Explorer move file - shows progress and prompts user in the event of a conflict
        # Ref: https://learn.microsoft.com/en-us/windows/win32/shell/folder-movehere
        [int]$fileAction = "16"
        $objShell = New-Object -ComObject "Shell.Application" 
        $objFolder = $objShell.NameSpace($DestinationFolder) 
        $objFolder.CopyHere($sourceItem, $fileAction)
    }
}

# Mount ISO image
$isoMount = Mount-DiskImage -ImagePath $WindowsServerISO -StorageType ISO -PassThru
$isoDriveLetter = ($isoMount | Get-Volume).DriveLetter
$isoDrivePath = $isoDriveLetter + ':\'

# Get Windows versions from ISO image
[string[]]$winVersions = (Get-WindowsImage -ImagePath "$isoDrivePath\sources\install.wim").ImageName
Write-Host "`nThe version of Windows Server on the ISO are:" -ForegroundColor Cyan
Out-Host -InputObject $winVersions

# Create prompt and ask user to insert a USB drive
do {
    $userInput = Read-Host -Prompt "`nPlease insert a USB drive to be formatted and press 'Enter' to continue"
    [array]$usbDrives = Get-Disk | Where-Object { $_.BusType -eq "USB" }
} while (
    $usbDrives.count -eq 0
)

if ($usbDrives.count -eq 1) {
    $usbDrive = $usbDrives[0]
}
elseif ($usbDrives.count -gt 1) {
    $usbDrives | Format-Table Number, @{n = "Size"; e = { [math]::Round($_.Size / 1GB, 2) } }, FriendlyName, PartitionStyle, IsReadOnly
    $userInput = Read-Host -Prompt "Enter the number of the USB drive to be formatted"
    $USBDrive = Get-Disk -Number $userInput
}
else {
    Write-Error "An error occurred selecting a USB drive"
}

# Clean USB Drive (erase everything)
$usbDrive | Clear-Disk -RemoveData -Confirm:$false -PassThru

if ($BootType -eq "GPT") {
    # Convert Disk to GPT
    $usbDrive | Set-Disk -PartitionStyle GPT
 
    # Create partition primary and format to FAT32
    $usbVolume = $usbDrive | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel WinServer
    $usbVolumePath = $usbVolume.DriveLetter + ':\'

    # Check USB volume free space - must be larger than 7GB
    $usbVolumeInfo = Get-CimInstance Win32_Volume | Where-Object { $_.Name -eq $usbVolumePath }
    [int64]$usbVolumeFreeSpace = $usbVolumeInfo.FreeSpace
    if ($usbVolumeFreeSpace -lt 7516192768) {
        Write-Error "The USB flash drive volume must have more than 7GB of free space available."
    }

    # Create temp directory for new image
    $winImageDate = (Get-Date).ToString('MMddyyyy-HHmm')
    [string]$winImageFolderPath = $env:TEMP + '\' + 'WinImage' + '_' + $winImageDate
    $winImageFolder = New-Item -Path $winImageFolderPath -ItemType Directory -Force

    # Check Windows volume free space
    $winImageVolumeInfo = Get-CimInstance Win32_Volume | Where-Object { $_.Name -eq $winImageFolder.Root.Name }
    [int64]$winImageVolumeFreeSpace = $winImageVolumeInfo.FreeSpace
    if ($winImageVolumeFreeSpace -lt 8589934592) {
        Write-Error "The Windows hard drive must have more than 8GB of free space available."
    }

    # Copy Files to temporary new image folder
    Write-Host "`nCopying files to local temp folder..." -ForegroundColor Cyan
    Copy-Item -Path $isoDrivePath -Destination $winImageFolderPath -Recurse -Force
    
    # Split and copy install.wim (because of 4GB file size limitation of FAT32)
    Set-ItemProperty -Path "$winImageFolderPath\sources\install.wim" -Name IsReadOnly -Value $false
    $splitImageResult = Split-WindowsImage -ImagePath "$winImageFolderPath\sources\install.wim" -SplitImagePath "$winImageFolderPath\sources\install.swm" -FileSize 4096 -CheckIntegrity
    
    # Copy Files to USB (Ignore install.wim)
    Write-Host "`nCopying files to USB drive..." -ForegroundColor Cyan
    Copy-FolderItem -SourceFolder $winImageFolderPath -DestinationFolder $usbVolumePath

    # Remove temp files
    Remove-Item -Path $winImageFolderPath -Recurse -Confirm:$false -Force
}
elseif ($BootType -eq "MBR") {
    # Ensure Disk is MBR
    $usbDrive | Set-Disk -PartitionStyle MBR
 
    # Create partition primary, format to NTFS, and set to active
    $usbVolume = $usbDrive | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel WinServer
    $usbVolume | Get-Partition | Set-Partition -IsActive $true
    $usbVolumePath = $usbVolume.DriveLetter + ':\'
 
    # Copy Files to USB
    Write-Host "`nCopying files to USB drive..." -ForegroundColor Cyan
    Copy-FolderItem -SourceFolder $isoDrivePath -DestinationFolder $usbVolumePath
}

# Dismount ISO
$diskDismount = Dismount-DiskImage -ImagePath $WindowsServerISO

Write-Host "`nUSB Windows Server $BootType installer created" -ForegroundColor White -BackgroundColor DarkGreen
