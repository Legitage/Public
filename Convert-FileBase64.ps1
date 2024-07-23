<#PSScriptInfo
.VERSION 1.0.0
.GUID f782e008-46d9-4932-bcd8-ef563e947342
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS Convert File Base64 Encode Decode
.LICENSEURI https://example.com/
.PROJECTURI https://example.com/
.RELEASENOTES
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Converts a binary file into a Base64 encoded text file or vice versa

    .DESCRIPTION
    Enables conversion of a file/zip to and from a Base64 encoded text file format

    .PARAMETER SampleParam
    Name of parameter and an explanation of its purpose

    .NOTES
    Lightweight copy/paste commands for remote systems:
    $sourceFilePath = "C:\Temp\Something.xyz"
    $base64FilePath = "C:\Temp\SomethingElse.b64"
    $destinationFilePath = "D:\Folder\Something.xyz"
    [IO.File]::WriteAllBytes($base64FilePath, [char[]][Convert]::ToBase64String([IO.File]::ReadAllBytes($sourceFilePath)))
    [IO.File]::WriteAllBytes($destinationFilePath, [Convert]::FromBase64String([char[]][IO.File]::ReadAllBytes($base64FilePath)))
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [switch]$To,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [switch]$From,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [System.IO.FileInfo]$FilePath
)

#Requires -Version 5.0

Function Get-FileName {
    <#
    .SYNOPSIS
    Prompts user for input (invokes Windows Dialog box)

    .NOTES
    Reference: https://devblogs.microsoft.com/scripting/hey-scripting-guy-can-i-open-a-file-dialog-box-with-windows-powershell/
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [System.IO.FileInfo]$DefaultFolderPath = "$env:USERPROFILE\Desktop"
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.initialDirectory = $DefaultFolderPath
    $openFileDialog.filter = "All files (*.*)| *.*"
    $openFileDialog.ShowDialog() | Out-Null
    
    return $openFileDialog.filename
} 

Function Convert-ToBase64File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [System.IO.FileInfo]$InputFilePath
    )

    # Check for curly braces in filename and remove if needed
    if (($InputFilePath.BaseName -like "*{*") -or ($InputFilePath.BaseName -like "*}*")) {
        $fileName = $InputFilePath.BaseName -replace '{', '_' -replace '}', '_'
    }
    else {
        $fileName = $InputFilePath.BaseName
    }   
    $fileType = $InputFilePath.Extension -replace '\.'
    $outputFilePath = $($InputFilePath.DirectoryName) + '\' + $fileName + '{' + $fileType + '}' + '.b64'
    [IO.File]::WriteAllBytes($outputFilePath, [char[]][Convert]::ToBase64String([IO.File]::ReadAllBytes($InputFilePath)))
    Write-Host "`n$InputFilePath converted to Base64 encoded file: $outputFilePath" -ForegroundColor Green
}

Function Convert-FromBase64File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [System.IO.FileInfo]$InputFilePath
    )

    $fileName = $InputFilePath.BaseName -replace '{', '.' -replace '}'
    $outputFilePath = $($InputFilePath.DirectoryName) + '\' + $fileName
    [IO.File]::WriteAllBytes($outputFilePath, [Convert]::FromBase64String([char[]][IO.File]::ReadAllBytes($InputFilePath)))
    Write-Host "`n$InputFilePath Base64 file decoded to: $outputFilePath" -ForegroundColor Green
}

if (-not $FilePath) {
    [System.IO.FileInfo]$FilePath = Get-FileName
}

if ($To) {
    Convert-ToBase64File -InputFilePath $FilePath
}
elseif ($From) {
    Convert-FromBase64File -InputFilePath $FilePath
}
else {
    Write-Error "Please specify either the '-To' or '-From' switch"
}
