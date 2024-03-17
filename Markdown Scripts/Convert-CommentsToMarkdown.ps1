<#PSScriptInfo
.VERSION 1.0.0
.GUID 5037983c-2a0f-4485-afff-d3b55945820d
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS markdown numbered comments
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES 
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Parses script file for numbered comments and outputs a markdown numbered list file

    .DESCRIPTION
    Comments in the specified script file are parsed and those containing a version build style number are ordered and converted 
    into a numbered markdown list that is copied to the clipboard or optionally written to a .md file in the same directory

    .PARAMETER FilePath
    Option to specify the powershell script file path and skip the Windows dialog box

    .EXAMPLE
    .\Convert-CommentsToMarkdown.ps1 "C:\MyRepo\MyCoolScript.ps1"

    .NOTES
    Comments need to start with 1.0.0, 1.1.0, 2.0.0, etc... and not contain gaps in the numbering sequence
    If there are gaps in the numbering sequence, the markdown file will be fine, but the list will be automatically renumbered when rendered/converted
#>

[CmdletBinding()]
param (
    [parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Enter the full path to the script file")]
    [System.IO.FileInfo]$FilePath,

    [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
    [switch]$OutputToFile
)

#Requires -Version 5.1

function Open-PsFileDialog {
    <#
    .SYNOPSIS
    Prompts user to select a file (invokes Windows Dialog box)

    .NOTES
    Reference: https://devblogs.microsoft.com/scripting/hey-scripting-guy-can-i-open-a-file-dialog-box-with-windows-powershell/
    #>

    [System.IO.FileInfo]$defaultFolderPath = $PSScriptRoot
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select a Markdown File"
    $openFileDialog.InitialDirectory = $defaultFolderPath
    $openFileDialog.Filter = "MD Files (*.ps1;*.psm1)|*.ps1;*.psm1|All Files (*.*)|*.*"
    $openFileDialog.ShowDialog() | Out-Null

    return $openFileDialog.Filename
}

$folderPath = $FilePath.DirectoryName
$fileName = $FilePath.BaseName
$scriptComments = Get-Content $FilePath | Where-Object { ($_ -like "*# *") -and ($_ -notlike "*<#*") }
[string[]]$numberedComments = $scriptComments | Select-String -Pattern '\d+\.\d+\.\d+'
$numberedComments = $numberedComments.TrimStart()
$numberedComments = $numberedComments -replace '# '
$versionedComments = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($numberedComment in $numberedComments) {
    $numbered = $numberedComment.Split(' ')[0]
    [version]$numberedVersion = $numbered
    if (($numberedVersion.Build -eq 0) -and ($numberedVersion.Minor -eq 0)) {
        [string]$mdNumber = "$($numberedVersion.Major)."
    }
    elseif (($numberedVersion.Build -eq 0) -and ($numberedVersion.Minor -ne 0)) {
        [string]$mdNumber = "   $($numberedVersion.Minor)."
    }
    elseif (($numberedVersion.Build -ne 0) -and ($numberedVersion.Minor -ne 0)) {
        [string]$mdNumber = "      $($numberedVersion.Build)."
    }

    $modifiedComment = $numberedComment -replace $numbered, $mdNumber
    $versionedComment = [PSCustomObject]@{
        Number  = $numberedVersion
        Comment = $modifiedComment
    }
    $versionedComments.Add($versionedComment)
}

$versionedComments.Sort( { $args[0].Number.compareto($args[1].Number) } )
[string[]]$markdownComments = $versionedComments.Comment

$markdownComments | Set-Clipboard
Write-Host "Markdown formatted comments copied to clipboard."

if ($OutputToFile) {
    Out-File -InputObject $markdownComments -FilePath "$folderPath\$($fileName)_comments.md" -Encoding ascii -Width 400 -Force
    Write-Host "Markdown formatted comments written to $folderPath\$($fileName)_comments.md"
}
