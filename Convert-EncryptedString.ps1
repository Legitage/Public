
Function ConvertTo-EncryptedString {
    <#
    .SYNOPSIS
    Convert a plain text string to an encrypted string with a random 192 bit encryption key

    .DESCRIPTION
    Can be used to store a password securely as an encrypted string and decode it later with the encryption key
    The encryption key is a byte array that must be converted to/from a string to be saved

    .EXAMPLE
    ConvertTo-EncryptedString -String "SomeText" or
    ConvertTo-EncryptedString "SomeText" or
    "SomeText" | ConvertTo-EncryptedString
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
}

Function ConvertFrom-EncryptedString {
    <#
    .SYNOPSIS
    Convert an encrypted string string with random key back to plain text

    .DESCRIPTION
    Can is used to reverse the encrypted string created by ConvertTo-EncryptedString
    
    .EXAMPLE
    ConvertFrom-EncryptedString -EncryptedString $encryptedStringInfo.Encrypted_String -EncryptionKey $encryptedStringInfo.Encryption_Key
    ConvertFrom-EncryptedString "EncryptedString" "EncryptionKey"
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
    $simpleString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))

    return $simpleString
}
