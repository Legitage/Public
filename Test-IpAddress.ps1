<#PSScriptInfo
.VERSION 1.0.0
.GUID 7ab1cff9-bc8d-4ef0-b4ec-60bd18cb6622
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
    Returns valid CIDR IP addresses from the given IP address list

    .DESCRIPTION
    Takes a list of CIDR IPv4 and IPv6 addresses, if none exists, an empty list is returned.
    Will also filter out invalid IP addresses that are neither IPv4 or IPv6.

    .PARAMETER AddressesList
    The list of IPv4 and/or IPv6 CIDR addresses

    .PARAMETER FilterType
    Option to only return IPv4 or IPv6 addresses effectively filtering out the other
#>

[CmdletBinding(PositionalBinding = $true)]
param(
    [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [array]$AddressList,

    [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
    [ValidateSet("IPv4", "IPv6")]
    [string]$FilterType
)

# PowerShell 5.x required. The version of PowerShell included with Windows 10
#Requires -Version 5.0

begin {
    # Source: https://regexr.com/50csh
    $ipv4CidrRegEx = "^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)(\/([1-9]|[1-2][0-9]|3[0-2])){0,1}$"
    
    # Source https://www.regextester.com/93988
    $ipv6CidrRegEx = "^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$"
    
    $ipv4List = [System.Collections.ArrayList]::new()
    $ipv6List = [System.Collections.ArrayList]::new()
    $ipList = [System.Collections.ArrayList]::new()
}
process {

    foreach ($address in $AddressList) {
        if (($address -match $iPv4CidrRegEx) -and ($FilterType -ne "IPv6")) {
            [void]$ipv4List.Add($address)
        }
        if (($address -match $iPv6CidrRegEx) -and ($FilterType -ne "IPv4")) {
            [void]$ipv6List.Add($address)
        }
    }
}
end {

    if ($ipv4List.count -gt 0) {
        $ipList.AddRange($ipv4List)
    }

    if ($ipv6List.count -gt 0) {
        $ipList.AddRange($ipv6List)
    }

    return $ipList
}
