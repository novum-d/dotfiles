#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$OpenManualSetupLinks
)

$ErrorActionPreference = "Stop"

function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is not available. Install App Installer from Microsoft Store, then run this script again."
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    Write-Host "Checking $Id..."
    $installed = winget list --id $Id --exact --accept-source-agreements 2>$null

    if ($LASTEXITCODE -eq 0 -and $installed -match [regex]::Escape($Id)) {
        Write-Host "Already installed: $Id"
        return
    }

    Write-Host "Installing $Id..."
    winget install `
        --id $Id `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements
}

Assert-Winget

$packages = @(
    "WinDynamicDesktop.WinDynamicDesktop",
    "RamenSoftware.Windhawk",
    "Rainmeter.Rainmeter",
    "Microsoft.PowerToys"
)

foreach ($package in $packages) {
    Install-WingetPackage -Id $package
}

if ($OpenManualSetupLinks) {
    $links = @(
        "https://windhawk.net/",
        "https://www.droptopfour.com/",
        "https://github.com/creewick/MontereyRainmeter",
        "https://github.com/ful1e5/apple_cursor"
    )

    foreach ($link in $links) {
        Start-Process $link
    }
}

Write-Host ""
Write-Host "Base packages are installed. Continue with README.md for Windhawk mods, Rainmeter skins, cursor, and PowerToys settings."
