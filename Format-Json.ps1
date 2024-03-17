Function Format-Json {
    <#
    .SYNOPSIS
    Formats JSON file output cleaner and more consistent with Newtonsoft.Json then the built-in 'ConvertTo-Json'

    .DESCRIPTION
    Formats JSON file output cleaner and more consistent with Newtonsoft.Json then the built-in 'ConvertTo-Json'

    .NOTES 
    Source: https://github.com/PowerShell/PowerShell/issues/2736
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$json
    )
    
    $indent = 0;
    ($json -Split '\n' | ForEach-Object {
        if ($_ -match '[\}\]]') {
            $indent--
        }
        $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
        if ($_ -match '[\{\[]') {
            $indent++
        }
        $line
    }
    ) -Join "`n"
}
