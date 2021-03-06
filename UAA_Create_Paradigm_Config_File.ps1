﻿<#
    .SYNOPSIS
    This scripts create a Parradigm Config file.

    .DESCRIPTION
    UAA's Paradigm Config file requires a custom configuration that includes the hostname that must be created on each machine so that it will run. 
    This script will create a custom config file for each machine as it is being deployed.


    .NOTES
    File Name	: UAA_Minitab_CreateNetworkLicense.ps1
    Author		: Chris Axtell - cbaxtell@uaa.alaska.edu/John Yoakum - jyoakum@alaska.edu
    Requires	: PowerShell
#>

# The path on the local workstation where the Minitab license file needs to be created
$OutputFile="C:\scripts\EposConfig.cfg"

# License File values
$InstallationPath="C:/Program Files/Paradigm/Paradigm-17/Applications"
$LicenseFile="7507@cas-licensing05.ua.ad.alaska.edu"
$machineID=$($env:computername)

# Generic windows setting for adding carriage return, new line codes
$OFS="`r`n"

# Build up the license file syntax
# Yes for some reason the license file generated by Minitab has a blank line at the begin so we include it in ours.
$ConfigFile="[Applications]" + $OFS + "PNSGroupDesc0=" + $machineID + $OFS + "LicenseFile=" + $LicenseFile + $OFS + "PNSGroupHosts0=" + $machineID + $OFS + "InstallationPath=" + $InstallationPath + $OFS + "[Services]" + $OFS + "Hostname=" + $machineID + $OFS


# Uncomment out the following line for debugging purposes, it'll output the license file to the PowerShell console
#Write-Host $LicenseFile

Set-Content -Encoding Unicode -Path $OutputFile -Value $ConfigFile