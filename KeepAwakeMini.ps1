<#PSScriptInfo
.VERSION 1.0.0
.GUID 5bcd20b3-47ce-40ce-ba96-15efbf2f84da
.AUTHOR Chad Armitage
.COMPANYNAME N/A
.COPYRIGHT Chad Armitage
.TAGS markdown numbered comments
.LICENSEURI https://github.com/Legitage/Public/blob/main/LICENSE
.PROJECTURI https://github.com/Legitage/Public
.RELEASENOTES 
    1.0.0  Initial release
#>

#Requires -Version 5.1
[int]$Minutes = 480
Add-Type -AssemblyName System.Windows.Forms
$wScriptShell = New-Object -ComObject WScript.Shell
$currentTime = Get-Date
$endTime = $currentTime.AddMinutes($Minutes)
$sleepTimeBase = 20

function Invoke-Sleep {
    $randSleepOffset = Get-Random -Minimum 2 -Maximum 9
    $sleepTime = $sleepTimeBase + $randSleepOffset
    Start-Sleep -seconds $sleepTime
}

while ($currentTime -lt $endTime) {
    $wScriptShell.SendKeys('+{F15}')
    Invoke-Sleep
    $currentTime = Get-Date
}
