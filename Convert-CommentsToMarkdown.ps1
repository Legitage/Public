<#PSScriptInfo
.VERSION 1.0.0
.GUID 5037983c-2a0f-4485-afff-d3b55945820d
.AUTHOR Chad Armitage
.COMPANYNAME
.COPYRIGHT Chad Armitage
.TAGS markdown numbered comments
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public/tree/main/New-WinServerUsbInstall
.RELEASENOTES 
#>

<#
    .SYNOPSIS
    Parses script file for numbered comments and outputs a markdown numbered list file

    .DESCRIPTION
    Comments in the specified script file are parsed and those containing a version build style number are ordered 
    and converted into a numbered markdown list that is written to a .md file in the same directory

    .PARAMETER SampleParam
    Name of parameter and an explanation of its purpose

    .EXAMPLE
    .\New-ScriptComments.ps1 "C:\Repo\Engineering\MyCoolScript.ps1"

    .NOTES
    Comments need to start with 1.0.0, 1.1.0, 2.0.0, etc... and not contain gaps in the numbering sequence
    If there are gaps in the numbering sequence, the markdown file will be fine, but the list will be automatically renumbered when rendered/converted
#>

[CmdletBinding()]
param (
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Enter the full path to the script file")]
    [System.IO.FileInfo]$File
)

#Requires -Version 5.1

$folderPath = $File.DirectoryName
$fileName = $File.BaseName
$scriptComments = Get-Content $File | Where-Object { ($_ -like "*# *") -and ($_ -notlike "*<#*") }
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
        "Number"  = $numberedVersion
        "Comment" = $modifiedComment
    }
    $versionedComments.Add($versionedComment)
}

$versionedComments.Sort( { $args[0].Number.compareto($args[1].Number) } )
[string[]]$markdownComments = $versionedComments.Comment

Out-File -InputObject $markdownComments -FilePath "$folderPath\$($fileName)_tmp.md" -Encoding ascii -Width 400 -Force
