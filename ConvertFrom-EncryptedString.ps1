<#PSScriptInfo
.VERSION 1.0.0
.GUID 5b340af7-df3f-42b1-b6f6-81ed48d1c653
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS Convert Encrypted String
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES 
    1.0.0  Initial release
#>

<#
    .SYNOPSIS
    Convert an encrypted string with random key back into a secure string

    .DESCRIPTION
    Can be used to reverse the encrypted string created by ConvertTo-EncryptedString
    
    .EXAMPLE
    ConvertFrom-EncryptedString.ps1 -EncryptedString $encryptedStringInfo.Encrypted_String -EncryptionKey $encryptedStringInfo.Encryption_Key
    ConvertFrom-EncryptedString.ps1 "EncryptedString" "EncryptionKey"

    .COPYRIGHT Chad Armitage
    .LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
    .PROJECTURI https://github.com/Legitage/Public
#>

[CmdletBinding()]
param(
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
    [string]$EncryptedString,

    [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
    [string]$EncryptionKey
)

[byte[]]$byteKey = [System.Text.ASCIIEncoding]::ASCII.GetBytes($EncryptionKey)
$secureString = $EncryptedString | ConvertTo-SecureString -Key $byteKey

return $secureString
