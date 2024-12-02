<#PSScriptInfo
.VERSION 1.0.0
.GUID a2a4ac10-0af7-44d5-b3bf-69bcdaf4ead2
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
    Convert a plain text string to an encrypted string with a random 192 bit encryption key

    .DESCRIPTION
    Can be used to store a password securely as an encrypted string and decode it later with the encryption key
    The encryption key is a byte array that must be converted to/from a string to be saved

    .EXAMPLE
    ConvertTo-EncryptedString.ps1 -String "SomeText" or
    ConvertTo-EncryptedString.ps1 "SomeText" or
    "SomeText" | ConvertTo-EncryptedString.ps1
#>

[CmdletBinding()]
param(
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$String
)

begin {
    $encryptedStringInfo = [System.Collections.ArrayList]::new()
    [byte[]]$byteKey = 1..24 | ForEach-Object { Get-Random -Minimum 65 -Maximum 122 }
}
process {
    $encryptedString = $String | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $byteKey
    [string]$stringKey = [System.Text.Encoding]::ASCII.GetString($byteKey)
}
end {
    $encryptedStringOutput = @{"Encrypted_String" = $encryptedString }
    $encryptionKeyOutput = @{"Encryption_Key" = $stringKey }
    [void]$encryptedStringInfo.Add($encryptedStringOutput)
    [void]$encryptedStringInfo.Add($encryptionKeyOutput)
    return $encryptedStringInfo
}
