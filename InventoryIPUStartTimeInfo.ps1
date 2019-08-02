﻿#WaaS Info Script Phase 1 of 2.  
#Phase 1 is at start of TS, grabs basic info and writes to registry.
#
#  IPU Keys:
#   IPULastRun
#   IPUExecutionTypeUser
#   IPUUserLoggedOn
#   IPUDeploymentID
#   IPUPackageID - Required for OSUninstall
#   IPUAttempts
#   IPUUserAccount
#   IPUPendingReboot
#   WaaS_Stage


#Function to increment the IPUAttemps Key for each run

function Set-RegistryValueIncrement {
    [cmdletbinding()]
    param (
        [string] $path,
        [string] $Name
    )

    try { [int]$Value = Get-ItemPropertyValue @PSBoundParameters -ErrorAction SilentlyContinue } catch {}
    Set-ItemProperty @PSBoundParameters -Value ($Value + 1).ToString() 
}


#Setup TS Environment
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
}
catch
{
	Write-Verbose "Not running in a task sequence."
}

if ($tsenv)
    {

    $tsBuild = $tsenv.Value("SMSTS_Build") #Get Build Number from TS Variable.
    $registryPath = "HKLM:\$($tsenv.Value("RegistryPath"))\$($tsenv.Value("SMSTS_Build"))" #Sets Registry Location

    
    #Create Registry Keys if needed
    if ( -not ( test-path $registryPath ) ) { 
        new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null
    }
    #Writes the Start Time to a Key in the Parent (WaaS) with the name of the TS, so we can keep track of when we've run which TS.
    New-ItemProperty -Path "HKLM:\$($tsenv.Value("RegistryPath"))" -Name $tsenv.Value("SMSTS_StartTSTime") -Value $tsenv.Value("_SMSTSPackageName") -Force
    
    #Writes Into to the WaaS\Build Number\ Key
    New-ItemProperty -Path $registryPath -Name "IPULastRun" -Value $TSEnv.Value('SMSTS_StartTSTime') -Force
    New-ItemProperty -Path $registryPath -Name "IPUExecutionTypeUser" -Value $tsenv.Value("_SMSTSUserStarted") -Force
    New-ItemProperty -Path $registryPath -Name "IPUUserLoggedOn" -Value $tsenv.Value("LOGGEDONUser") -Force
    New-ItemProperty -Path $registryPath -Name "IPUDeploymentID" -Value $TSEnv.Value('_SMSTSAdvertID') -Force
    New-ItemProperty -Path $registryPath -Name "IPUPackageID" -Value $TSEnv.Value('_SMSTSPackageID') -Force

    #Creates or Increments the IPUAttempts Value
    Set-RegistryValueIncrement -Path $registryPath -Name IPUAttempts

    #Creates the IPURebootPending Value, for those curious if a pending reboot might affect upgrades
    New-ItemProperty -Path $registryPath -Name "IPURebootPending" -Value (Invoke-WmiMethod -Namespace 'root\ccm\ClientSDK' -Class CCM_ClientUtilities -Name DetermineIfRebootPending).RebootPending -Force

    #Grabs User Name of the user Logged on.
    if ($tsenv.Value("_SMSTSUserStarted") -eq "True")