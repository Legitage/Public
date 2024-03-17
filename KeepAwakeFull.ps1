<# 
    .SYNOPSIS
    Prevents computer from going to sleep

    .DESCRIPTION
    Simulates a Shift+F15 keystroke every minute. Also moves the mouse pointer backand forth.

    .PARAMETER Minutes
    Specify the number of minutes to run. If not specified, default is 14 hours.

    .PARAMETER MouseMove
    Moves the mouse pointer back and forth (useful for some web based apps)

    .EXAMPLE
    .\KeepAwake.ps1 -Minutes 120

    .NOTES
    PowerShell script inspired by http://www.zhornsoftware.co.uk/caffeine/
    Forked from: https://gist.github.com/jamesfreeman959/231b068c3d1ed6557675f21c0e346a9c
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [int]$Minutes = 840,

    [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
    [switch]$MoveMouse
)

#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
$wScriptShell = New-Object -ComObject WScript.Shell
$currentTime = Get-Date
$endTime = $currentTime.AddMinutes($Minutes)
$sleepTimeBase = 20
$mouseMovementSize = 2

function Invoke-Sleep {
    $randSleepOffset = Get-Random -Minimum 2 -Maximum 10
    $sleepTime = $sleepTimeBase + $randSleepOffset
    Start-Sleep -seconds $sleepTime
}

function Move-MousePointer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateSet("Forward","Back")]
        [string]$Direction
    )

    $mousePosition = [Windows.Forms.Cursor]::Position

    if ($Direction -eq "Forward"){
      $mousePosition.X = $mousePosition.X + $mouseMovementSize
      $mousePosition.Y = $mousePosition.Y + $mouseMovementSize
    }

    if ($Direction -eq "Back"){
      $mousePosition.X = $mousePosition.X - $mouseMovementSize
      $mousePosition.Y = $mousePosition.Y - $mouseMovementSize
    }

    [Windows.Forms.Cursor]::Position = $mousePosition
}

while ($currentTime -lt $endTime) {
    $wScriptShell.SendKeys('+{F15}')
    if ($MoveMouse){
      Move-MousePointer -Direction Forward
    }
    Invoke-Sleep
    if ($MoveMouse){
      Move-MousePointer -Direction Back
    }
    Invoke-Sleep
    $currentTime = Get-Date
}
