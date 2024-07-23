<#PSScriptInfo
.VERSION 1.0.0
.GUID 63116a77-d7f7-4109-b6bd-d29491e5d4a5
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS Exchange On-Prem Attributes
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Clears all the Exchange attributes from Active Directory Objects

    .DESCRIPTION
    Takes a list of Active Directory users DNs and clears the values of all the Exchange attributes.
    PowerShell replacement for ExMgmt 'Remove Exchange Attributes' option and/or KillMail.exe (both defunct)
    Can accept list of user DNs from a string array object, the pipeline, or prompt user for a file of DNs

    .PARAMETER UserDnList
    String array list of AD User Distinguished Name values

    .NOTES
    ToDo: Make separate script/function Gets DNs based on USNs and then passed them in via pipeline
    ToDo: Research input validation and/or how to handle different object types
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [string[]]$UserDnList
)

#Requires -Version 5.0

begin {
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

    $exAttributes = @(
        "homeMDB",
        "homeMTA",
        "legacyExchangeDN",
        "mail",
        "mailNickname",
        "mDBUseDefaults",
        "msExchAddressBookFlags",
        "msExchALObjectVersion",
        "msExchArchiveGUID",
        "msExchArchiveQuota",
        "msExchArchiveStatus",
        "msExchArchiveWarnQuota",
        "msExchDumpsterQuota",
        "msExchDumpsterWarningQuota",
        "msExchELCMailboxFlags",
        "msExchEwsEnabled",
        "msExchHideFromAddressLists",
        "msExchHomeServerName",
        "msExchMailboxGuid",
        "msExchPoliciesExcluded",
        "msExchPoliciesIncluded",
        "msExchProvisioningFlags",
        "msExchRecipientDisplayType",
        "msExchRecipientSoftDeletedStatus",
        "msExchRecipientTypeDetails",
        "msExchRemoteRecipientType",
        "msExchTextMessagingState",
        "msExchUMDtmfMap",
        "msExchUserAccountControl",
        "msExchUserHoldPolicies",
        "msExchVersion",
        "msExchWhenMailboxCreated",
        "proxyAddresses",
        "showInAddressBook",
        "targetAddress",
        "textEncodedORAddress"
    )

    if ($null -eq $UserDnList) {
        [System.IO.FileInfo]$filePath = Get-FileName
        [string[]]$UserDnList = Get-Content -Path $filePath
    }

}
process {

    foreach ($dn in $UserDnList) {
        $objUser = New-Object DirectoryServices.DirectoryEntry "LDAP://$($dn.distinguishedName)"
        foreach ($attribute in $exAttributes) {
            $objUser.PutEx(1, $attribute, 0)
        }
        $objUser.SetInfo()
    }
    
}
end {
    Write-Host "Exchange attributes have been cleared for the specified Distinguished Names" 
}