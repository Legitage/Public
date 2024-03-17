
Function New-RandomAsciiPassword {
    <#
   .SYNOPSIS
   Generates a random password string

   .DESCRIPTION
   Returns a random password of printable ASCII characters

   .PARAMETER PasswordLength
   Specifies the length of the password. If not specified, the default is 16

   .PARAMETER SecureString
   Returns a secure string instead of plain text string
   #>

    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateRange(5,62)]
        [int]$PasswordLength = 16,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]$SecureString

    )

    $byteArray = New-Object -TypeName System.Byte[] -ArgumentList $PasswordLength
    $randomNumbers = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $complexityCheck = '(?-i)^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!"#\$%&''\(\)*\+,\-\./:;<=>\?@\[\\\]\^_`\{\|\}~]).{5,62}$'
    
    Function New-AsciiPasswordString {
        $asciiPassword = $null
        $randomNumbers.GetBytes($byteArray)
   
        for ( $b = 0; $b -lt $PasswordLength; $b++ ) {
            if (($byteArray[$b] -ge 33) -and ($byteArray[$b] -le 126)) {
                $validAscii = $byteArray[$b]
            }
            elseif ($byteArray[$b] -lt 33) {
                $validAscii = $byteArray[$b] + 33
            }
            elseif (($byteArray[$b] -gt 126) -and ($byteArray[$b] -le 220)) {
                $validAscii = $byteArray[$b] - 94
            }
            elseif ($byteArray[$b] -gt 220) {
                $validAscii = $byteArray[$b] - 188
            }

            $asciiPassword += [char]$validAscii	
        }

        return $asciiPassword
    }

    do {
        $newPassword = New-AsciiPasswordString
    }
    while ($newPassword -notmatch $complexityCheck)

    if ($SecureString) {
        $newPassword = $newPassword | ConvertTo-SecureString -AsPlainText -Force
    }

    return $newPassword
}
