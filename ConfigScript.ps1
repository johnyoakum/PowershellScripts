﻿<#  Upgrade Analytics Configuration Script

 DISCLAIMER

 The scripts included in the "Upgrade Analytics Configuration Script" package are not supported under any Microsoft standard support program or service.
 The scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any
 implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the scripts
 and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of 
 the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss
 of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if 
 Microsoft has been advised of the possibility of such damages.

#>

#----------------------------------------------------------------------------------------------------------
#
#                                          Parameter Declarations
#
#---------------------------------------------------------------------------------------------------------- 


Param(
# run mode (Deployment or Pilot)
[Parameter(Mandatory=$true, Position=1)]
[string]$runMode,

# File share to store logs
[Parameter(Mandatory=$true, Position=2)]
[string]$logPath,

# Commercial ID provided to you
[Parameter(Mandatory=$true, Position=3)]
[string]$commercialIDValue,

# logMode == 0 log to console only
# logMode == 1 log to file and console
# logMode == 2 log to file only
[Parameter(Mandatory=$true, Position=4)]
[string]$logMode,

#To enable IE data, set AllowIEData=IEDataOptIn and set IEOptInLevel
[Parameter(Position=5)]
[string]$AllowIEData,

#IEOptInLevel = 0 Internet Explorer data collection is disabled
#IEOptInLevel = 1 Data collection is enabled for sites in the Local intranet + Trusted sites + Machine local zones
#IEOptInLevel = 2 Data collection is enabled for sites in the Internet + Restricted sites zones
#IEOptInLevel = 3 Data collection is enabled for all sites 
[Parameter(Position=6)]
[string]$IEOptInLevel,

[Parameter(Position=7)]
[string]$DeviceNameOptIn, 

[Parameter(Position=8)]
[string]$AppInsightsOptIn,

[Parameter(Position=9)]
[string]$NoOfAppraiserRetries = 30,

[Parameter(Position=10)]
[string]$ClientProxy = "Direct",

[Parameter(Position=11)]
[int]$HKCUProxyEnable,

[Parameter(Position=12)]
[string]$HKCUProxyServer 
)

#----------------------------------------------------------------------------------------------------------
#
#                                          Global Variables
#
#---------------------------------------------------------------------------------------------------------- 

# Version of the Upgrade Analytics Configuration script
$global:scriptVersion = "2.4.4 - 10.10.2018"

# Script folder root
$global:scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# Diagnostics folder root
$global:sDiagRoot = $global:scriptRoot + "\Diagnostics"

# Guid for this run of the script (to be used by AppInsights)
$global:runGuid = [System.Guid]::NewGuid()

# The OS Version
$global:osVersion = (Get-WmiObject Win32_OperatingSystem).Version

# The OS Build number
[int] $global:osBuildNumber = (Get-WmiObject Win32_OperatingSystem).BuildNumber

# OS name
$global:operatingSystemName = (Get-WmiObject Win32_OperatingSystem).Name

# minimum appraiser version
$global:appraiserMinVersion = 10014979


# For Pilot runMode, Appraiser will run in verbose mode and verbose logs will be collected. The Diagnostics folder need to be present under the scriptRoot for this. Please use the Pilot package.
switch($runMode)
{
    "Pilot"
    {
        $global:isVerboseMode = $true
    }
    "Deployment"
    {
        $global:isVerboseMode = $false
    }
    default
    {
        $global:isVerboseMode = $false
    }
}

# Set the exit code to the first exception exit code
$global:errorCode = [string]::Empty;

# Total error count while running the script
[int]$global:errorCount = 0;

# Machine Sqm ID
$global:sClientId = [String]::Empty;

# Machine name
$global:machineName = [Environment]::MachineName

# Appraise Version if appraiser.dll is present
$global:appraiserVersion

# This will contain the WinHttp proxy if netsh winhttp show proxy has a system wide proxy set. ClientProxy=System scenario
$global:winHttpProxy = [string]::Empty

# This will be set to true when logged on user impersonation is turned on
$global:isImpersonatedUser = $false

# bool variable to indicate if authproxy related registry key is set ot not
$global:authProxySupported = $false

# App Insights configured correctly
$global:appInsightsConfigured = $false

# Variable to make sure we only throw exception once in case we are not able to send app insights
$global:excepThrownForSendEventToAppInsights = $false

# If any exception occurs it will stop the script execution or it will execute Catch
$erroractionPreference = "stop"

#----------------------------------------------------------------------------------------------------------------
#
#                               Configure and validate upgrade analytics data collection - Main 
#
#----------------------------------------------------------------------------------------------------------------

$main = {
    Try 
    {           
        # Quit if System variable WINDIR is not set
        Try
        {
            $global:windir=[System.Environment]::ExpandEnvironmentVariables("%WINDIR%")
        }
        Catch
        {
            $exceptionDetails = "Exception: " + $_.Exception.Message + "HResult: " + $_.Exception.HResult
            Write-Host "Failure finding system variable WINDIR. $exceptionDetails" "Error" "23" -ForegroundColor Red
            [System.Environment]::Exit(23)
        }

        # Get Sqm Machine Id    
        Get-SqmID 

        # The script will log to both console and log file if logMode is not among the expected values
        if ($logMode -ne 0 -and $logMode -ne 1 -and $logMode -ne 2)
        {
            Write-Host "Incorrect Log Mode provided, defaulting to 1(log to file and console)" -ForegroundColor Red
            $logMode = 1
        }
        
        # Create the log file if logMode requires logging to file.
        CreateLogFile                

        # Setup App Insights
        if($AppInsightsOptIn -eq "true")
        {
            ConfigureAppInsights 
        }

        Log "Starting Upgrade Analytics Configuration Script" "Start" $null "ScriptStart"

        # The script should run as System
        if(([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem -eq $false )
        {
            Log "The Upgrade Analytics configuration script is not running under System account. Please run the script as System." "Error" "27" "RunningAsSystemCheck"
            Log "Script finished with error(s)" "Failure" "27" "ScriptEnd"
            [System.Environment]::Exit(27)
        }

        # Check machine SKU and quit if the SKU is not supported
        CheckMachineSKU        
    
        #Log script data
        Log ""
        Log "******************************** Upgrade Readiness ********************************************"
        Log "UTC DateTime: $global:utcDate"
        Log "Script Version: $global:scriptVersion"
        Log "OS Version: $global:osVersion" 
        Log "RunMode: $runMode"
        Log "RunID: $global:runGuid"
        Log "LogPath: $logPath" 
        Log "CommercialIdInput: $commercialIDValue" 
        Log "LogMode: $logMode" 
        Log "Verbose: $global:isVerboseMode" 
        Log "AllowIEData: $AllowIEData" 
        Log "IEOptInLevel: $IEOptInLevel"
        Log "ClientProxy: $ClientProxy"
        Log "DeviceNameOptIn: $DeviceNameOptIn"        
        Log "AppInsightsOptIn: $AppInsightsOptIn"        
        Log "Architecture: $ENV:Processor_Architecture"  
        Log "Machine Sqm Id: $global:sClientId"
        Log "Machine Name: $global:machineName"
        Log "*********************************************************************************************"
        Log ""
        Log "Powershell Execution Policies: "
        if ($global:isVerboseMode -eq $true)
        {
           $output = Get-ExecutionPolicy -List
           foreach($values in $output)
           {
               Log $values
           }
        }
        Log ""

        # Check if Commercial ID mentioned in RunConfig.bat is a GUID
        CheckCommercialId

        # Set up Commercial ID to value provided in script parameters
        SetupCommercialId
        
        # For Windows 10 check if telemetry opt in is set to basic or higher.
        # For down level machines set the telemetry opt in if it is not set.
        CheckTelemetryOptIn

        # If AllowIEData is enabled then setup SetIEDataOptIn
        if ($AllowIEData -eq "IEDataOptIn")
        {
            SetIEDataOptIn
        }
        
        # Check WinHTTP and WinINET proxy settings
        CheckProxySettings
         
        # Check registry keys related to user proxy
        CheckUserProxy
        
        # Check network connectivity to Vortex using the VortexConnectionTest tool
        CheckVortexConnectivity           

        # Check recent UTC connectivity
        if($global:osBuildNumber -gt 17134)
        {
            CheckUtcCsp
        }

        # Check if reboot is required
        CheckRebootRequired
    
        # Check Appraiser KB version
        CheckAppraiserKB
    
        # Sets VerboseMode to enable appraiser logging value to the registry
        if ($global:isVerboseMode -eq $true)
        {
            SetAppraiserVerboseMode
        }
    
        # Sets RequestAllAppraiserVersions key
        if($global:osBuildNumber -lt 10240)
        {
            SetRequestAllAppraiserVersions
        }
    
        # Check the status of Diagtrack service
        CheckDiagtrackService

        # Check the status of Microsoft Account Sign-In Assistant Service
        if($global:osBuildNumber -ge 10240)
        {
            CheckMSAService
        }

        # Opt in to send the device name to Microsoft.
        if($DeviceNameOptIn -eq "true")
        {
            if($global:osBuildNumber -ge 16300)
            {
                SetDeviceNameOptIn
            }
        }

        # force a OneSettings download to ensure that telemetry settings are up to date
        CleanupOneSettings

        # Genereate new Compat Report
        RunAppraiser

        # Force a Census run to make sure data gets sent
        RunCensus

        # Collect the logs, disable appraiser verbose mode, end traces
        if ($global:isVerboseMode -eq $true)
        {
            Try
            {
                Log "Running diagnose_internal.cmd" 
                $CMD = "$global:sDiagRoot\diagnose_internal.cmd" 
                & $CMD $global:sDiagRoot $global:logFolder                
            }
            Catch
            {
                Log "diagnose_internal.cmd failed with unexpected exception" "Error" "37" "RunDiagnose_Internal.cmd" $_.Exception.HResult $_.Exception.Message
            }

            # Disable appriaser verbose mode after running the appriaser
            DisableAppraiserVerboseMode
        }
    
        if($global:errorCount -gt 0)
        {
            if($logMode -ne 0)
            {
                Log "Script finished with $global:errorCount errors. Please check the log $global:logFile to see the error exit codes. Please see https://aka.ms/UAErrorCodes for more information."
                Log "For additional help, Zip the Log folder $global:logFolder and email the upgrade analytics team at uasupport@microsoft.com"
            }
            else
            {
                Log "Script finished with $global:errorCount errors. Please check the errors and see https://aka.ms/UAErrorCodes for more information."
                Log "For additional debugging, please run in Pilot mode and email the logs to upgrade analytics tean at uasupport@microsoft.com"
            }
        }

        #exit with success or first failed exit code
        if(($global:errorCode -eq $null) -or ($global:errorCode -eq [string]::Empty))
        {
            Log "Script succeeded" "Success" "0" "ScriptEnd"
            [System.Environment]::Exit(0)
        }
        else
        {
            Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
            exit $global:errorCode            
        }
    }
    Catch
    {
        Log "Unexpected error occured while executing the script" "Error" "1" "UnExpectedException" $_.Exception.HResult $_.Exception.Message
        Log "Script failed" "Failure" "1" "ScriptEnd"
        [System.Environment]::Exit(1)
    }
}

#----------------------------------------------------------------------------------------------------------
#
#                                          Function Definitions
#
#---------------------------------------------------------------------------------------------------------- 

function CreateLogFile
{
    if($logMode -ne 0)
    {
        Write-Host "Creating Log File"

        $timeStart=Get-Date
        $timeStartString=$timeStart.ToString("yy_MM_dd_HH_mm_ss")
        $logFolderName = "UA_" + $timeStartString
        $sqmID = $global:sClientId
        if(($sqmID -ne $null) -and ($sqmID -ne [string]::Empty))
        {
            $logFolderName = $logFolderName + "_" + $sqmID.Replace("s:", "")
        }
        $fileName = $logFolderName+".txt"
        $global:logFolder = $logPath +"\"+$logFolderName
        $global:logFile=$global:logFolder+"\"+$fileName
                
        Try
        {
            New-Item $global:logFolder -type directory | Out-Null
            New-Item $global:logFile -type file | Out-Null
            Write-Host "Log File created successfully: $global:logFile"
        }
        Catch
        {
            Write-Host "Could not create log file at the given logPath: $logPath" -ForegroundColor Red
            $hexHresult = "{0:X}" -f $_.Exception.HResult
            $exceptionMessage = $_.Exception.Message
            Write-Host "Exception: $exceptionMessage HResult:  0x$hexHresult" -ForegroundColor Red
            [System.Environment]::Exit(28)
        }
    }
}

function CheckMachineSKU
{
    if($global:operatingSystemName.ToLower().Contains("server"))
    {
        Log "The operating system is server SKU: '$global:operatingSystemName'. The script does not support server SKUs, so exiting" "Error" "26" "CheckMachineSKU"
        Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
        [System.Environment]::Exit($global:errorCode)
    }
}

function Get-SqmID
{
    Try
    {
        $sqmID = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\SQMClient -Name MachineId).MachineId
        $global:sClientId = "s:" + $sqmID.Substring(1).Replace("}", "") 
    }
    Catch
    {

        Write-Host "Get-SqmID failed with unexpected exception." -ForegroundColor Red
        $hexHresult = "{0:X}" -f $_.Exception.HResult
        $exceptionMessage = $_.Exception.Message
        Write-Host "Exception: $exceptionMessage HResult:  0x$hexHresult" -ForegroundColor Red
        [System.Environment]::Exit(38)
    }
}

function CheckCommercialId
{
    Try
    {
        Log "Start: CheckCommercialId"
        
        if(($commercialIDValue -eq $null) -or ($commercialIDValue -eq [string]::Empty))
        {
	         Log "The commercialID parameter is incorrect. Please edit runConfig.bat and set the CommercialIDValue and rerun the script" "Error" "6" "SetupCommercialId"
             Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
             [System.Environment]::Exit($global:errorCode)
        }

        [System.Guid]::Parse($commercialIDValue) | Out-Null

    }
    Catch
    {
        If(($commercialIDValue -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")) -eq $false)
        {
            Log "CommercialID mentioned in RunConfig.bat should be a GUID. It currently set to '$commercialIDValue'" "Error" "48" "CheckCommercialId"
            Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
            [System.Environment]::Exit($global:errorCode)
        }
    }

     Log "Passed: CheckCommercialId"
}

function SetupCommercialId
{
    Try
    {
        Log "Start: SetupCommercialId"

        $vCommercialIDPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        $GPOCommercialIDPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

        # Check first if Commercial ID Path exists
        $testCIDPath = Test-Path -Path $vCommercialIDPath
        $testGPOCIDPath = Test-Path -Path $GPOCommercialIDPath
        
        if($testCIDPath -eq $false)
        {
	        Try 
            {
		        New-Item -Path $vCommercialIDPath -ItemType Key
	        }
	        Catch 
            {
		        Log "SetupCommercialId failed to create registry key path: $vCommercialIDPath" "Failure" "8" "SetupCommercialId" $_.Exception.HResult $_.Exception.Message
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
	         }
         }

        if ((Get-ItemProperty -Path $vCommercialIDPath -Name CommercialId -ErrorAction SilentlyContinue) -eq $null)
        {
	        Try 
            {		    
		        New-ItemProperty -Path $vCommercialIDPath -Name CommercialId -PropertyType String -Value $commercialIDValue
	        }

	        Catch 
            {
		        Log "SetupCommercialId failed to write Commercial Id: $commercialIDValue at registry key path: $vCommercialIDPath" "Error" "9" "SetupCommercialId" $_.Exception.HResult $_.Exception.Message
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
	        }
        }
        else
        {
            $existingCommerciaId = (Get-ItemProperty -Path $vCommercialIDPath -Name CommercialId).CommercialId
            if($existingCommerciaId -ne $commercialIDValue)
            {
	            Log "Commercial Id already exists: $existingCommerciaId. Updating it to provided value: $commercialIDValue" "Warning" $null "SetupCommercialId"

                Try
                {
                    Set-ItemProperty -Path $vCommercialIDPath -Name CommercialId  -Value $commercialIDValue
                }
                Catch
                {
		            Log "SetupCommercialId failed to update CommercialId: $commercialIDValue at registry key path: $vCommercialIDPath" "Error" "9" "SetupCommercialId" $_.Exception.HResult $_.Exception.Message
                    Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                    [System.Environment]::Exit($global:errorCode)
                }
             }
             else
             {
                Log "Commercial Id already set to the same value as provided in the script parameters." 
             }
        }

        if($testGPOCIDPath -eq $true)
        {
            $GPOCIDValue = (Get-ItemProperty -Path $GPOCommercialIDPath -Name CommercialId -ErrorAction SilentlyContinue).CommercialId
            if ( $GPOCIDValue -ne $null -and $GPOCIDValue -ne $commercialIDValue)
            {
                 Log "There is a different CommercialID: $GPOCIDValue present at the GPO path: $GPOCommercialIDPath. This will take precedence over the CommercialID: $commercialIDValue provided in the script. Please fix the CommercialID mismatch at the GPO location." "Error" "53" "SetupCommercialId"
            }
        }
    
        Log "Passed: SetupCommercialId"
        
    }
    Catch
    {
        Log "SetupCommercialId failed with unexpected exception." "Error" "11" "SetupCommercialId" $_.Exception.HResult $_.Exception.Message
        Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
        [System.Environment]::Exit($global:errorCode)
    }

}

function CheckTelemetryOptIn
{
    Log "Start: CheckTelemetryOptIn"
    $vCommercialIDPathPri1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $vCommercialIDPathPri2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    
    Try
    {
        if($global:operatingSystemName.ToLower().Contains("windows 10"))
        {
            $allowTelemetryPropertyPri1 = (Get-ItemProperty -Path $vCommercialIDPathPri1 -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry
            $allowTelemetryPropertyPri2 = (Get-ItemProperty -Path $vCommercialIDPathPri2 -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry
            
            if($allowTelemetryPropertyPri1 -ne $null)
            {
                Log " AllowTelemetry property value at registry key path $vCommercialIDPathPri1 : $allowTelemetryPropertyPri1" 

                $allowTelemetryPropertyType1 = (Get-ItemProperty -Path $vCommercialIDPathPri1 -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry.gettype().Name
                if($allowTelemetryPropertyType1 -ne "Int32")
                {
              
                  Log "AllowTelemetry property value at registry key path $vCommercialIDPathPri1 is not of type REG_DWORD. It should be of type REG_DWORD" "Error" "62" "CheckTelemetryOptIn"
                
                }

                if(-not ([int]$allowTelemetryPropertyPri1 -ge 1 -and [int]$allowTelemetryPropertyPri1 -le 3))
                {
                    Log "Please set the Windows telemetry level (AllowTelemetry property) to Basic (1) or above at path $vCommercialIDPathPri1. Check https://docs.microsoft.com/en-us/windows/deployment/update/windows-analytics-get-started for more information." "Error" "63" "CheckTelemetryOptIn"
                }
            }
            
            if($allowTelemetryPropertyPri2 -ne $null)
            {
                Log " AllowTelemetry property value at registry key path $vCommercialIDPathPri2 : $allowTelemetryPropertyPri2"

                $allowTelemetryPropertyType2 = (Get-ItemProperty -Path $vCommercialIDPathPri2 -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry.gettype().Name
                if($allowTelemetryPropertyType2 -ne "Int32")
                {
                    Log "AllowTelemetry property value at registry key path $vCommercialIDPathPri2 is not of type REG_DWORD. It should be of type REG_DWORD" "Error" "64" "CheckTelemetryOptIn"
                }

                if(-not ([int]$allowTelemetryPropertyPri2 -ge 1 -and [int]$allowTelemetryPropertyPri2 -le 3))
                {
                    Log "Please set the Windows telemetry level (AllowTelemetry property) to Basic (1) or above at path $vCommercialIDPathPri2. Check https://docs.microsoft.com/en-us/windows/deployment/update/windows-analytics-get-started for more information." "Error" "65" "CheckTelemetryOptIn"
                }
            }        
        }
        else
        {
            Log "Enabling sending inventory by setting CommercialDataOptIn property at registry key path: $vCommercialIDPathPri2" 

            if ((Get-ItemProperty -Path $vCommercialIDPathPri2 -Name CommercialDataOptIn -ErrorAction SilentlyContinue) -eq $null)
            {
	            Try 
                {
		            New-ItemProperty -Path $vCommercialIDPathPri2 -Name CommercialDataOptIn -PropertyType DWord -Value 1
	            }
                Catch 
                {
		            Log "CheckTelemetryOptIn failed with unexpected exception while setting CommercialDataOptIn property at registry key path: $vCommercialIDPathPri2" "Error" "10" "CheckTelemetryOptIn" $_.Exception.HResult $_.Exception.Message
                    return
	            }
            }
            else
            {
	            Log "CommercialDataOptIn property is already set at registry key path: $vCommercialIDPathPri2. Inventory sending is already enabled" 
            }
        }

        Log "Passed: CheckTelemetryOptIn"
    }
    Catch
    {
        Log "CheckTelemetryOptIn failed with unexpected exception." "Error" "40" "CheckTelemetryOptIn" $_.Exception.HResult $_.Exception.Message
    }
}

function SetIEDataOptIn
{
    try
    {
        Log "Start: SetIEDataOptIn"
        $vIEDataOptInPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        
        # Check first if IEdata collection ID Path exists
        $testDCPath = Test-Path -Path $vIEDataOptInPath
        if($testDCPath -eq $false)
        {
            Try 
            {
                New-Item -Path $vIEDataOptInPath -ItemType Key
            }
            Catch 
            {
                Log "SetIEDataOptIn failed to create registry key path: $vIEDataOptInPath" "Error" "8" "SetIEDataOptIn" $_.Exception.HResult $_.Exception.Message
                return
            }
        }
        
        if ((Get-ItemProperty -Path $vIEDataOptInPath -Name IEDataOptIn -ErrorAction SilentlyContinue) -eq $null)
        {
            Try 
            {
                Set-ItemProperty -Path $vIEDataOptInPath -Name IEDataOptIn -Type DWord -Value $IEOptInLevel
            }
            Catch 
            {
                Log "SetIEDataOptIn failed when writing IEDataOptIn property to registry key path: $vIEDataOptInPath" "Error" "24" "SetIEDataOptIn" $_.Exception.HResult $_.Exception.Message
                return
            }
        }
        else
        {
            $existingIEDataOptIn = (Get-ItemProperty -Path $vIEDataOptInPath -Name IEDataOptIn).IEDataOptIn
	        
            if($existingIEDataOptIn -ne $IEOptInLevel)
            {
                Log "IEDataOptIn already exists IEOptInLevel: $existingIEDataOptIn. Updating IEDataOptIn value to $IEOptInLevel" "Warning" $null "SetIEDataOptIn"

                Try
                {
                    Set-ItemProperty -Path $vIEDataOptInPath -Name IEDataOptIn -Value $IEOptInLevel
                }
                Catch
                {
		            Log "SetIEDataOptIn failed when writing IEDataOptIn property to registry" "Error" "24" "SetIEDataOptIn" $_.Exception.HResult $_.Exception.Message
                    return
                 }
             }
             else
             {
                Log "IEDataOptIn is already set to the same value as provided in the script parameters" 
             }
         }
        Log "Passed: SetIEDataOptIn"
    }
    Catch
    {
        Log "SetIEDataOptIn failed with unexpected exception." "Error" "25" "SetIEDataOptIn" $_.Exception.HResult $_.Exception.Message
    }
}

function CheckVortexConnectivity
{
    Log "Start: CheckVortexConnectivity"

    Try
    {   
        $exeName = "$global:scriptRoot\VortexConnectionTest.exe"
        $vortexConnectionTestoutput = cmd /c $exeName '2>&1' | Out-String
        $vortextConnectionTestExitCode = $LASTEXITCODE
        Log $vortexConnectionTestoutput
       
        if($LASTEXITCODE -ne 0) 
        {
            Log "CheckVortexConnectivity failed. Please check the complete tool output in the Log." "Error" "12" "CheckVortexConnectivity"                           
        }
        else
        {
            Log "Passed: CheckVortexConnectivity"
        }
    }
    Catch 
    {
	    Log "CheckVortexConnectivity failed with unexpected exception." "Error" "15" "CheckVortexConnectivity" $_.Exception.HResult $_.Exception.Message
    }
}

function CheckUtcCsp
{
    Log "Start: CheckUtcCsp"

    Try
    {
        #Check the WMI-CSP bridge (must be local system)
        $ClassName = "MDM_Win32CompatibilityAppraiser_UniversalTelemetryClient01"
        $BridgeNamespace = "root\cimv2\mdm\dmmap"
        $FieldName = "UtcConnectionReport"

        $CspInstance = get-ciminstance -Namespace $BridgeNamespace -ClassName $ClassName

        $Data = $CspInstance.$FieldName

        #Parse XML data to extract the DataUploaded field.
        $XmlData = [xml]$Data

        if (0 -eq $XmlData.ConnectionReport.ConnectionSummary.DataUploaded)
        {
            Log "CheckUtcCsp failed. The only recent data uploads all failed." "Error" "66" "CheckUtcCsp"
        }
        else
        {
            Log "Passed: CheckUtcCsp"
        }
    }
    Catch
    {
	    Log "CheckUtcCsp failed with unexpected exception." "Error" "67" "CheckUtcCsp" $_.Exception.HResult $_.Exception.Message
    }
}

function GetWinHttpProxy
{
   $binaryValue = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name WinHttpSettings).WinHttPSettings            
   $proxylength = $binaryValue[12]            
   if ($proxylength -gt 0) 
   {            
       # <proxy server>:<port> will be returned
       $global:winHttpProxy = -join ($binaryValue[(12+3+1)..(12+3+1+$proxylength-1)] | % {([char]$_)})
   }
}

function StartImpersonatingLoggedOnUser
{
Log "Start: StartImpersonatingLoggedOnUser"

Try
{
add-type @'
namespace mystruct {
using System;
using System.Runtime.InteropServices;
     [StructLayout(LayoutKind.Sequential)]
     public struct WTS_SESSION_INFO
     {
     public Int32 SessionID;

     [MarshalAs(UnmanagedType.LPStr)]
     public String pWinStationName;

     public WTS_CONNECTSTATE_CLASS State;
     }

     public enum WTS_CONNECTSTATE_CLASS
     {
     WTSActive,
     WTSConnected,
     WTSConnectQuery,
     WTSShadow,
     WTSDisconnected,
     WTSIdle,
     WTSListen,
     WTSReset,
     WTSDown,
     WTSInit
     } 
     }
'@

$wtsEnumerateSessions = @'
[DllImport("wtsapi32.dll", SetLastError=true)]
public static extern int WTSEnumerateSessions(
         System.IntPtr hServer,
         int Reserved,
         int Version,
         ref System.IntPtr ppSessionInfo,
         ref int pCount);
'@

$wtsenum = add-type -MemberDefinition $wtsEnumerateSessions -Name PSWTSEnumerateSessions -Namespace GetLoggedOnUsers -PassThru


$wtsqueryuserToken = @'
[DllImport("wtsapi32.dll", SetLastError=true)]
public static extern bool WTSQueryUserToken(UInt32 sessionId, out System.IntPtr Token);
'@

$wtsQuery = add-type -MemberDefinition $wtsqueryuserToken -Name PSWTSQueryServer -Namespace GetLoggedOnUsers -PassThru


[long]$count = 0
[long]$sessionInfo = 0
[long]$returnValue = $wtsenum::WTSEnumerateSessions(0,0,1,[ref]$sessionInfo,[ref]$count)
$datasize = [system.runtime.interopservices.marshal]::SizeOf([System.Type][mystruct.WTS_SESSION_INFO])
$userSessionID = $null
if ($returnValue -ne 0)
{
    for ($i = 0; $i -lt $count; $i++)
    {
        $element =  [system.runtime.interopservices.marshal]::PtrToStructure($sessionInfo + ($datasize * $i),[System.type][mystruct.WTS_SESSION_INFO])

        if($element.State -eq [mystruct.WTS_CONNECTSTATE_CLASS]::WTSActive)
        {
            $userSessionID = $element.SessionID
        }
     }

if($userSessionID -eq $null)
{
    Log "Could not impersonate logged on user. Continuing as System. Data will be sent when a user logs on." "Error" "41" "StartImpersonatingLoggedOnUser"
    return 
}

$userToken = [System.IntPtr]::Zero
$wtsQuery::WTSQueryUserToken($userSessionID, [ref]$userToken)


$advapiImpersonate = @'
[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool ImpersonateLoggedOnUser(System.IntPtr hToken);
'@

$impersonateUser = add-type -MemberDefinition $advapiImpersonate -Name PSImpersonateLoggedOnUser -PassThru
$impersonateUser::ImpersonateLoggedOnUser($UserToken)
$global:isImpersonatedUser = $true

Log "Passed: StartImpersonatingLoggedOnUser. Connected as logged on user"
}
else
{
    Log "Could not impersonate logged on user. Continuing as System. Data will be sent when a user logs on." "Error" "41" "StartImpersonatingLoggedOnUser"
}
}
Catch
{
    Log "StartImpersonatingLoggedOnUser failed with unexpected exception. Continuing as System. Data will be sent when a user logs on." "Error" "42" "StartImpersonatingLoggedOnUser" $_.Exception.HResult $_.Exception.Message
}
}

function EndImpersonatingLoggedOnUser
{
Try
{
    if($global:isImpersonatedUser -eq $true)
    {   Log "Start: EndImpersonatingLoggedOnUser"
        $advapiRevertToSelf = @'
        [DllImport("advapi32.dll", SetLastError=true)]
        public static extern bool RevertToSelf();
'@

        $revertToSelf = add-type -MemberDefinition $advapiRevertToSelf -Name PSRevertToSelf -PassThru
        $revertToSelf::RevertToSelf()        
        Log "Passed: EndImpersonatingLoggedOnUser."
        $global:isImpersonatedUser = $false
    }
}
Catch
{
    Log "EndImpersonatingLoggedOnUser failed with unexpected exception" "Error" "43" "EndImpersonatingLoggedOnUser" $_.Exception.HResult $_.Exception.Message
}
}

function CheckRebootRequired 
{
    Log "Start: CheckRebootRequired"
    Log "Checking if there is a pending reboot"
    Try
    {
        if (Test-Path $ExecutionContext.InvokeCommand.ExpandString('$env:WINDIR\winsxs\pending.xml'))
        {
           Log "CheckRebootRequired detected that there is a pending reboot required. Please reboot and rerun the the Upgrade Analytics configuration script" "Error" "16" "CheckRebootRequired"
           Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
           [System.Environment]::Exit($global:errorCode)
        }

        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")
        {
           Log "CheckRebootRequired detected that there is a pending reboot required. Please reboot and rerun the the Upgrade Analytics configuration script" "Error" "16" "CheckRebootRequired"
           Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
           [System.Environment]::Exit($global:errorCode)
        }

	    Log "Passed: CheckRebootRequired. Reboot is not needed."
    }
    Catch 
    {
	    Log "CheckRebootRequired failed with unexpected exception." "Error" "17" "CheckRebootRequired" $_.Exception.HResult $_.Exception.Message
    }
}

function CheckAppraiserKB
{
    Log "Start: CheckAppraiserKB"
    $kbLink = "https://docs.microsoft.com/en-us/windows/deployment/update/windows-analytics-get-started"
    
    Try
    {       
        # Checking appraiser version
        $minVersion =  $global:appraiserMinVersion 
          
        if (Test-Path "$global:windir\System32\appraiser.dll")
        {
            
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$global:windir\System32\appraiser.dll")
            [string]$majorPart = $versionInfo.FileMajorPart
            [string]$minorPart = $versionInfo.FileMinorPart
            [string]$buildPart = $versionInfo.FileBuildPart            
            $global:appraiserVersion= $majorPart + $minorPart + $buildPart
            Log "Appraiser MINVERSION of local appraiser.dll: $global:appraiserVersion"

            if([int]$global:appraiserVersion -lt [int]$minVersion )
            {
	            Log "CheckAppraiserKB detected that you have appraiser version: $global:appraiserVersion.  It needs to be updated to version: $minVersion or higher if available, for data to get collected correctly. Please check $kbLink for more information." "Error" "32" "CheckAppraiserKB"
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
            }
        }
        else
        {
            # Checking Appraiser KBs
            if($global:operatingSystemName.ToLower().Contains("windows 7"))
            {
                Log "Checking if KB2952664 is installed"
                $result = Get-Hotfix | where {$_.HotFixId -like "KB2952664"}

                if($result -eq $null -or $result -eq [string]::Empty)
                {
                    Log "KB2952664 is not installed. Please install via http://www.catalog.update.microsoft.com/Search.aspx?q=KB2952664" "Error" "18" "CheckAppraiserKB"
                    Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                    [System.Environment]::Exit($global:errorCode)
                }            
            }
            elseif($global:operatingSystemName.ToLower().Contains("windows 8.1"))
            {
                Log "Checking if KB2976978 is installed"
                $result = Get-Hotfix | where {$_.HotFixId -like "KB2976978"}

                if($result -eq $null -or $result -eq [string]::Empty)
                {
                    Log "KB2976978 is not installed. Please install via http://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB2976978" "Error" "18" "CheckAppraiserKB"
                    Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                    [System.Environment]::Exit($global:errorCode)
                }  
            }
            else
            {
                Log "Appraiser.dll not found. Please install the relevant KBs. Go to $kbLink for more information." "Error" "18" "CheckAppraiserKB" 
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
            }
         }
        
        Log "Passed: CheckAppraiserKB"
    }
    Catch 
    {
	    Log "CheckAppraiserKB failed with unexpected exception." "Error" "19" "CheckAppraiserKB" $_.Exception.HResult $_.Exception.Message
        Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
        [System.Environment]::Exit($global:errorCode)
    }
}

function SetAppraiserVerboseMode
{
    Log "Start: SetAppraiserVerboseMode"
    Try
    {
        $vAppraiserPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser"
        Log "Enabling Appraiser logs for debugging by setting VerboseMode property to 1 at the registry key path: $vAppraiserPath" 
        if ((Get-ItemProperty -Path $vAppraiserPath -Name VerboseMode -ErrorAction SilentlyContinue) -eq $null)
        {
	        Try 
            {
		        New-ItemProperty -Path $vAppraiserPath -Name VerboseMode -PropertyType DWord -Value 1
	        }
	        Catch 
            {
		        Log "SetAppraiserVerboseMode failed to write the VerboseMode property at registry key $vAppraiserPath. This is not fatal, script will continue." "Warning" $null "SetAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
                return
	        }
        }
        else
        {
	        Log "Appraiser verbose mode is already enabled" 
        }

        Log "Enabling Appraiser logs for debugging by setting TestHooksEnabled property to 1 at the registry key path: $vAppraiserPath" 
        if ((Get-ItemProperty -Path $vAppraiserPath -Name TestHooksEnabled -ErrorAction SilentlyContinue) -eq $null)
        {
	        Try 
            {
		        New-ItemProperty -Path $vAppraiserPath -Name TestHooksEnabled -PropertyType DWord -Value 1
	        }
	        Catch 
            {
		        Log "SetAppraiserVerboseMode failed to write the TestHooksEnabled property at registry key $vAppraiserPath. This is not fatal, script will continue." "Warning" $null "SetAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
                return
	        }
        }
        else
        {
	        Log "Appraiser TestHooksEnabled property is already set" 
        }
        
        Log "Passed: SetAppraiserVerboseMode"
    }
    Catch 
    {
	    Log "SetAppraiserVerboseMode failed with unexpected exception. This is not fatal, script will continue." "Warning" $null "SetAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
    }
}

function DisableAppraiserVerboseMode
{
    Log "Start: DisableAppraiserVerboseMode"
    Try
    {
        $vAppraiserPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser"
        if ((Get-ItemProperty -Path $vAppraiserPath -Name VerboseMode -ErrorAction SilentlyContinue) -ne $null)
        {
	        Try 
            {
		        Remove-ItemProperty -Path $vAppraiserPath -Name VerboseMode
	        }
	        Catch 
            {
		        Log "DisableAppraiserVerboseMode failed deleting VerboseMode property at registry key path: $vAppraiserPath. This is not fatal, script will continue." "Warning" $null "DisableAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
	        }
        }
        else
        {
	        Log "Appraiser VerboseMode key already deleted" 
        }

        Log "Passed: DisableAppraiserVerboseMode"
    }
    Catch 
    {
	    Log "DisableAppraiserVerboseMode failed with unexpected exception. This is not fatal, script will continue." "Warning" $null "DisableAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
    }
}

function SetRequestAllAppraiserVersions
{
    Log "Start: SetRequestAllAppraiserVersions"
    Try
    {
        $propertyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" 
        $propertyGPOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"  
        if(Test-Path -Path $propertyPath)
        {
            if ((Get-ItemProperty -Path $propertyPath -Name RequestAllAppraiserVersions -ErrorAction SilentlyContinue) -eq $null)
            {
	            Try 
                {
		            New-ItemProperty -Path $propertyPath -Name RequestAllAppraiserVersions -PropertyType DWord -Value 1
	            }
	            Catch 
                {
		            Log "SetRequestAllAppraiserVersions failed setting RequestAllAppraiserVersions property at registry key path: $propertyPath" "Error" "20" "SetRequestAllAppraiserVersions" $_.Exception.HResult $_.Exception.Message
                    return
                }
            }
            else
            {
                Try 
                {
		            Set-ItemProperty -Path $propertyPath -Name RequestAllAppraiserVersions -Value 1
	            }
	            Catch 
                {
		            Log "SetRequestAllAppraiserVersions failed setting RequestAllAppraiserVersions property at registry key path: $propertyPath" "Error" "20" "SetRequestAllAppraiserVersions" $_.Exception.HResult $_.Exception.Message
                    return
	            }
            }
        }

        if(Test-Path -Path $propertyGPOPath)
        {
            if ((Get-ItemProperty -Path $propertyGPOPath -Name RequestAllAppraiserVersions -ErrorAction SilentlyContinue) -eq $null)
            {
	            Try 
                {
		            New-ItemProperty -Path $propertyGPOPath -Name RequestAllAppraiserVersions -PropertyType DWord -Value 1
	            }
	            Catch 
                {
		            Log "SetRequestAllAppraiserVersions failed setting RequestAllAppraiserVersions property at registry key path: $propertyGPOPath" "Error" "20" "SetRequestAllAppraiserVersions" $_.Exception.HResult $_.Exception.Message
                    return
	            }
            }
            else
            {
                Try 
                {
		            Set-ItemProperty -Path $propertyPath -Name RequestAllAppraiserVersions -Value 1
	            }
	            Catch 
                {
		            Log "SetRequestAllAppraiserVersions failed setting RequestAllAppraiserVersions property at registry key path: $propertyGPOPath" "Error" "20" "SetRequestAllAppraiserVersions" $_.Exception.HResult $_.Exception.Message
                    return
	            }
            }
        }

        Log "Passed: SetRequestAllAppraiserVersions"
    }
    Catch 
    {
	    Log "SetRequestAllAppraiserVersions failed with unexpected exception." "Error" "21" "SetRequestAllAppraiserVersions" $_.Exception.HResult $_.Exception.Message
    }
}		


function CheckDiagtrackService
{
    $warningText1 = "CheckUTCKB The Diagnostics and Telemetry tracking service (diagtrack.dll version "
    $warningText2 = ") is old. "
    $warningText3 = " enables faster processing of insights and reduces overall latency for devices enrolled in Analytics. Learn more at "
    $warningText4 = "Get the update that enables faster processing of insights and reduces overall latency for devices enrolled in Analytics at "
    $kblink = "https://go.microsoft.com/fwlink/?linkid=2011593&clcid=0x409"

    Log "Start: CheckDiagtrackService"
    Try
    {
        if (Test-Path "$global:windir\System32\diagtrack.dll")
        {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$global:windir\System32\diagtrack.dll")

            [string]$majorPart = $versionInfo.FileMajorPart
            [string]$minorPart = $versionInfo.FileMinorPart
            [string]$buildPart = $versionInfo.FileBuildPart
            [string]$fileRevision = $versionInfo.FilePrivatePart

            $diagtrackVersion= $majorPart + $minorPart + $buildPart
            [string]$dot = "."
            $diagtrackFullVersion= $majorPart + $dot + $minorPart + $dot + $buildPart + $dot + $fileRevision
            [string]$diagtrackVersionFormatted= $majorPart + $dot + $minorPart + $dot + $buildPart
            Log "Diagtrack.dll version: $diagtrackVersion"
            Log "Diagtrack.dll full version: $diagtrackFullVersion"

            if([int]$diagtrackVersion -lt 10010586 )
            {
	            Log $warningText1$diagtrackFullVersion$warningText2$warningText4$kblink "Error" "44" "CheckDiagtrackService"
                return
            }

            [string]$minRevision = "0" 
            if($global:operatingSystemName.ToLower().Contains("windows 7"))
            {
                if([int]$diagtrackVersion -eq 10010586 -and [int]$fileRevision -lt 10007)
                {
                    $minRevision = "10007"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }
            }

            if($global:operatingSystemName.ToLower().Contains("windows 8.1"))
            {
                if([int]$diagtrackVersion -eq 10010586 -and [int]$fileRevision -lt 10007)
                {
                    $minRevision = "10007"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }
            }

            if($global:operatingSystemName.ToLower().Contains("windows 10"))
            {
                if([int]$diagtrackVersion -eq 10014393 -and [int]$fileRevision -lt 2513)
                {
                    $minRevision = "2513"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }

                if([int]$diagtrackVersion -eq 10015063 -and [int]$fileRevision -lt 1356)
                {
                    $minRevision = "1356"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }

                if([int]$diagtrackVersion -eq 10016299 -and [int]$fileRevision -lt 696)
                {
                    $minRevision = "696"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }

                if([int]$diagtrackVersion -eq 10017134 -and [int]$fileRevision -lt 320)
                {
                    $minRevision = "320"
                    $diagtrackVersionFormattedFull = $diagtrackVersionFormatted + $dot + $minRevision
                    Log $warningText1$diagtrackFullVersion$warningText2$diagtrackVersionFormattedFull$warningText3$kblink "warning" $null "CheckDiagtrackService"
                }
            }
        }
        else
        {
            Log "CheckUTCKB The Diagnostics and Telemetry tracking service (Diagtrack.dll) not found at $global:windir\System32. Get the update that enables faster processing of insights and reduces overall latency for devices enrolled in Analytics at $kblink" "Error" "45" "CheckDiagtrackService"
            return
        }

        $serviceName = "diagtrack"
        $serviceInfo = Get-Service -Name $serviceName
        $status = $serviceInfo.Status
        Log "Diagtrack Service Status: $status"

        if($status.ToString().ToLower() -ne "running")
        {
            Log "Diagtrack Service is not running. Please run the 'Connected User Experiences and Telemetry' service." "Error" "50" "CheckDiagtrackService"
            Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
            [System.Environment]::Exit($global:errorCode)
        }

        Log "Passed: CheckDiagtrackService"
    }
    Catch
    {
        Log "CheckDiagtrackService failed with an exception. Please check if 'Connected User Experiences and Telemetry' service exists and is running in a healthy state." "Error" "50" "CheckDiagtrackService" $_.Exception.HResult $_.Exception.Message
        Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
        [System.Environment]::Exit($global:errorCode)
    }
}

function CheckMSAService
{
    Log "Start: CheckMSAService"
    Try
    {
        $serviceInfo = Get-WmiObject win32_service -Filter "Name='wlidsvc'"
        $serviceStartMode = $serviceInfo.StartMode
        $serviceState = $serviceInfo.State

        Log "Microsoft Account Sign In Assistant Service State: $serviceState, StartMode: $serviceStartMode"

        if($serviceStartMode.ToString().ToLower() -eq "disabled")
        {           
            if($global:osBuildNumber -lt 16300)
            {
                Log "Microsoft Account Sign In Assistant Service is Disabled. Please make sure the service is up and running." "Error" "54" "CheckMSAService"
            }
            else
            {
                Log "Microsoft Account Sign In Assistant Service Disabled. Device will send SqmId instead of GlobalId"
            }                        
        }
        else
        {
            $isManualTriggeredStart = $false
            # Check if the service is Manual (Triggered Start)
            if($serviceStartMode.ToString().TOLower() -eq "manual")
            {
                if(Test-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\wlidsvc\TriggerInfo\')
                {
                    Log "Microsoft Account Sign In Assistant Service is Manual(Triggered Start)."
                    $isManualTriggeredStart = $true
                }
            }

            if($isManualTriggeredStart -eq $false)
            {            
                if($global:osBuildNumber -lt 16300 -and $serviceState.ToString().ToLower() -ne "running")
                {            
                    Log "Microsoft Account Sign In Assistant Service is not running. Please make sure the service is up and running." "Error" "54" "CheckMSAService"
                }
            }  
        }

        Log "Passed: CheckMSAService"
    }
    Catch
    {
        Log "CheckMSAService failed with an exception." "Warning" $null "CheckMSAService" $_.Exception.HResult $_.Exception.Message
    }
}

function SetDeviceNameOptIn
{
    Try
    {
        Log "Start: SetDeviceNameOptIn"

        $deviceNameOptInPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

        # Check first if the Path exists
        $testdeviceNameOptInPath = Test-Path -Path $deviceNameOptInPath
        
        
        if($testdeviceNameOptInPath -eq $false)
        {
	        Try 
            {
		        New-Item -Path $deviceNameOptInPath -ItemType Key
	        }
	        Catch 
            {
		        Log "SetDeviceNameOptIn failed to create registry key path: $deviceNameOptInPath" "Failure" "55" "SetDeviceNameOptIn" $_.Exception.HResult $_.Exception.Message
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
	         }
         }

        if ((Get-ItemProperty -Path $deviceNameOptInPath -Name AllowDeviceNameInTelemetry -ErrorAction SilentlyContinue) -eq $null)
        {
	        Try 
            {		    
		        New-ItemProperty -Path $deviceNameOptInPath -Name AllowDeviceNameInTelemetry -PropertyType DWord -Value 1
	        }
	        Catch 
            {
		        Log "SetDeviceNameOptIn failed to create property AllowDeviceNameInTelemetry at registry key path: $deviceNameOptInPath" "Error" "56" "SetDeviceNameOptIn" $_.Exception.HResult $_.Exception.Message
                Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                [System.Environment]::Exit($global:errorCode)
	        }
        }
        else
        {
            $existingValue = (Get-ItemProperty -Path $deviceNameOptInPath -Name AllowDeviceNameInTelemetry).AllowDeviceNameInTelemetry
            if($existingValue -ne 1)
            {
                Try
                {
                    Set-ItemProperty -Path $deviceNameOptInPath -Name AllowDeviceNameInTelemetry  -Value 1
                }
                Catch
                {
		            Log "SetDeviceNameOptIn failed to update AllowDeviceNameInTelemetry property to value 1 at registry key path: $deviceNameOptInPath" "Error" "57" "SetDeviceNameOptIn" $_.Exception.HResult $_.Exception.Message
                    Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
                    [System.Environment]::Exit($global:errorCode)
                }
            }
        }
    
        Log "Passed: SetDeviceNameOptIn"
        
    }
    Catch
    {
        Log "SetDeviceNameOptIn failed with unexpected exception." "Error" "58" "SetDeviceNameOptIn" $_.Exception.HResult $_.Exception.Message
        Log "Script finished with error(s)" "Failure" "$global:errorCode" "ScriptEnd"
        [System.Environment]::Exit($global:errorCode)
    }
}

function CleanupOneSettings
{
     Log "Start: CleanupOneSettings"
    Try
    {
        $serviceName = "diagtrack"
        Stop-Service -Name $serviceName
        
        $regKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\Diagtrack"
        $propertyValue = Get-ItemProperty -Path $regKeyPath -Name LastPersistedEventTimeOrFirstBoot  -ErrorAction SilentlyContinue
        if ($propertyValue -ne $null)
        {
            Log "LastPersistedEventTimeOrFirstBoot value at $regKeyPath is: $propertyValue"

            Try 
            {
                Remove-ItemProperty -Path $regKeyPath -Name LastPersistedEventTimeOrFirstBoot -Force
            }
            Catch 
            {
                Log "CleanupOneSettings failed to delete LastPersistedEventTimeOrFirstBoot property at registry key path: $regKeyPath" "Error" "59" "CleanupOneSettings" $_.Exception.HResult $_.Exception.Message
            }
        }

        $regKeyPathSettingsReqs = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\Diagtrack\SettingsRequests"
        $itemValue = Get-ItemProperty -Path $regKeyPathSettingsReqs -ErrorAction SilentlyContinue
        if ($itemValue -ne $null)
        {
            Log "Registry Key details for $regKeyPathSettingsReqs are: $itemValue" 

            Try 
            {
                Remove-Item -Path $regKeyPathSettingsReqs -Recurse -Force
            }
            Catch 
            {
                Log "CleanupOneSettings failed to delete registry key: $regKeyPathSettingsReqs" "Error" "60" "CleanupOneSettings" $_.Exception.HResult $_.Exception.Message
            }
        }
        
        Start-Service -Name $serviceName

        Log "Passed: CleanupOneSettings"
    }
    Catch
    {
        Log "CleanupOneSettings failed with an exception." "Error" "61" "CleanupOneSettings" $_.Exception.HResult $_.Exception.Message
    }
}

function RunAppraiser
{
    Try
    {
	    Log "Start: RunAppraiser"
        Log "Attempting to run inventory...This may take a few minutes to complete, please do not cancel the script."

        do
        {
            CompatTelRunner.exe -m:appraiser.dll -f:DoScheduledTelemetryRun ent | out-null
            $appraiserLastExitCode = $LASTEXITCODE
            $appraiserLastExitCodeHex = "{0:X}" -f $appraiserLastExitCode
            
            if($appraiserLastExitCode -eq 0x80070021)
            {
                Log "RunAppraiser needs to run CompatTelRunner.exe, but it is already running. Waiting for 60 seconds before retry."
                Start-Sleep -Seconds 60
            }
            else
            {
                break
            }

            $NoOfAppraiserRetries = $NoOfAppraiserRetries - 1
            
        }While($NoOfAppraiserRetries -gt 0)
        
	    if ($appraiserLastExitCode -ne 0x0) 
        {
            if ($appraiserLastExitCode -lt 0x0)
            {
		        Log "RunAppraiser failed. CompatTelRunner.exe exited with last error code: 0x$appraiserLastExitCodeHex."  "Error" "33" "RunAppraiser" "0x$appraiserLastExitCodeHex" "CompatTelRunner.exe returned with an error code."
            }
            else
            {
                Log "RunAppraiser succeeded with a return code: 0x$appraiserLastExitCodeHex."
            }
	    } 
        else 
        {
            Log "Passed: RunAppraiser"
	    }         
    }
    Catch 
    { 
        Log "RunAppraiser failed with unexpected exception." "Error" "22" "RunAppraiser" $_.Exception.HResult $_.Exception.Message
    }
}

function RunCensus
{
    Log "Start: RunCensus"
    Try
    {
        $censusRunRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Census"
        
        if($(Test-Path $censusRunRegKey) -eq $false)
        {
	        New-Item -Path $censusRunRegKey -ItemType Key
        }

        # Turn Census FullSync mode on
        Log "Setting property: FullSync to value 1 at registry key path $censusRunRegKey to turn on Census FullSync mode"
        if ((Get-ItemProperty -Path $censusRunRegKey -Name FullSync -ErrorAction SilentlyContinue) -eq $null)
        {
	        New-ItemProperty -Path $censusRunRegKey -Name FullSync -PropertyType DWord -Value 1	        
        }
        else
        {
            Set-ItemProperty -Path $censusRunRegKey -Name FullSync  -Value 1
        }


        # Run Census and validate the run
        # Census invocation commands are different for Windows 10 and Downlevel
        [int] $runCounterBefore = (Get-ItemProperty -Path $censusRunRegKey).RunCounter

        if($runCounterBefore -eq $null)
        {
            New-ItemProperty -Path $censusRunRegKey -Name RunCounter -PropertyType DWord -Value 0	   
        }

        if($global:operatingSystemName.ToLower().Contains("windows 10"))
        {
            $censusExe = "$global:windir\system32\devicecensus.exe" 
            if(Test-Path -Path $censusExe)
            { 
                Log "Running $censusExe" 
                & $censusExe                
            }
            else
            {
                Log "$censusExe path not found" "Error" "52" "RunCensus"
                return   
            }
        }
        else
        {
            CompatTelRunner.exe -m:generaltel.dll -f:DoCensusRun
        }

        [int] $runCounterAfter = (Get-ItemProperty -Path $censusRunRegKey).RunCounter
        $returnCode = (Get-ItemProperty -Path $censusRunRegKey).ReturnCode
        $startTime = Get-Date (Get-ItemProperty -Path $censusRunRegKey).StartTime
        $endTime = Get-Date (Get-ItemProperty -Path $censusRunRegKey).EndTime

        if($returnCode -eq 0)
        {
            if($runCounterAfter -gt $runCounterBefore -and $endTime -gt $startTime)
            {
                Log "Passed: RunCensus"
            }
            else
            {
                Log "Census did not run correctly. Registray data at $censusRunRegKey are: RunCounter Before trying to run Census:$runCounterBefore, RunCounter after trying to run Census:$runCounterAfter, ReturnCode:$returnCode, UTC StartTime:$startTime, UTC EndTime:$endTime" "Warning" $null "RunCensus"
            }
        }
        else
        {
            Log "Census returned a non zero ReturnCode:$returnCode" "Warning" $null "RunCensus"
        }

        # Turn Census FullSync mode off
        Log "Resetting property: FullSync to value 0 at registry key path $censusRunRegKey to turn off Census FullSync mode"
        Set-ItemProperty -Path $censusRunRegKey -Name FullSync  -Value 0
        
    }
    Catch
    {
        Log "RunCensus failed with unexpected exception" "Error" "51" "RunCensus" $_.Exception.HResult $_.Exception.Message
    }
}

function CheckProxySettings
{
    Log "Start: CheckProxySettings"
    Try
    {
        Log "WinHTTP Proxy settings:"
        $systemProxy = netsh winhttp show proxy
        foreach($output in $systemProxy)
        {
            Log "$output"
        }

        Log "WinINET Proxy settings:"
        $pathHKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
        $pathHKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"

        if($runMode -eq "Pilot")
        {
            Log "Proxy properties at path $pathHKCU :"
            Log "ProxyEnable: $HKCUProxyEnable"
        
            if($HKCUProxyServer -ne $null -and $HKCUProxyServer -ne [string]::Empty)
            { 
                Log "ProxyServer: $HKCUProxyServer"
            }
        }
       
        Log "Proxy properties at path $pathHKLM :"
        [int]$HKLMProxyEnable = (Get-ItemProperty -Path $pathHKLM).ProxyEnable
        Log "ProxyEnable: $HKLMProxyEnable"        
        $HKLMProxyServer = (Get-ItemProperty -Path $pathHKLM).ProxyServer
        
        if($HKLMProxyServer -ne $null -and $HKLMProxyServer -ne [string]::Empty)
        {
            Log "ProxyServer: $HKLMProxyServer"
        }

        Log "Passed: CheckProxySettings"
    }
    Catch
    {
        Log "CheckProxySettings failed with unexpected exception." "Error" "34" "CheckProxySettings" $_.Exception.HResult $_.Exception.Message
    }
}

function CheckUserProxy
{
    Try
    {
        Log "Start: CheckUserProxy"
        $dataCollectionRegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

        [int]$disableEnterpriseAuthProxy = (Get-ItemProperty -Path $dataCollectionRegKeyPath -Name DisableEnterpriseAuthProxy -ErrorAction SilentlyContinue).DisableEnterpriseAuthProxy

        Log "DisableEnterpriseAuthProxy property value at registry key path: $dataCollectionRegKeyPath : $disableEnterpriseAuthProxy"

        if($ClientProxy.ToLower() -eq "user")
        {
             if($disableEnterpriseAuthProxy -ne 0)
            {
                Log "DisableEnterpriseAuthProxy property is not set to 0 at registry key path $dataCollectionRegKeyPath. It needs to be set to 0 for UTC to work in authenticated proxy environment." "Error" "30" "CheckUserProxy"
                return
            }
        }       

        Log "Passed: CheckUserProxy"
    }
    Catch
    {
        Log "CheckUserProxy failed with unexpected exception." "Error" "35" "CheckUserProxy" $_.Exception.HResult $_.Exception.Message
    }
}

function Log($logMessage, $logLevel, $errorCode, $operation, $exceptionHresult, $exceptionMessage)
{
    $global:logDate = Get-Date -Format s
    $global:utcDate = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $logMessageForAppInsights = $logMessage

    if(($logLevel -eq $null) -or ($logLevel -eq [string]::Empty))
    {
        $logLevel = "Info"
    }

    if($logLevel -eq "Error")
    {
        $textColor = "Red"

        # check and update the errorCode (the script will exit with the first errorCode)
        if(($errorCode -ne $null) -and ($errorCode -ne [string]::Empty))
        {
            if(($global:errorCode -eq $null) -or ($global:errorCode -eq [string]::Empty))
            {
                $global:errorCode = $errorCode
            }

            $logMessage = "ErrorCode " + $errorCode + " : " + $logMessage            
        }

        if($exceptionHresult -ne $null)
        {
             $logMessage = $logMessage + " HResult: " + $exceptionHresult
        }

        if($exceptionHresult -ne $null)
        {
            $logMessage = $logMessage + " ExceptionMessage: " + $exceptionMessage
        }

        $global:errorCount++
    }
    elseif($logLevel -eq "Exception")
    {
        $textColor = "Red" 
    }
    elseif($logLevel -eq "Warning")
    {
        $textColor = "Yellow"
    }
    else
    {
        $textColor = "White"
    }

    # send log to AppInsights
    if($AppInsightsOptIn -eq "true")
    {
        if($logLevel -eq "Error"  -or $logLevel -eq "Warning" -or $logLevel -eq "Start" -or $logLevel -eq "Failure" -or $logLevel -eq "Success")
        {
            SendEventToAppInsights $operation $logMessageForAppInsights $logLevel $global:utcDate $errorCode $exceptionHresult $exceptionMessage
        }
    }

    if ($logMode -eq "0")
    {
        Try 
        {
            Write-Host "$global:logDate : $logMessage" -ForegroundColor $textColor
        }
        Catch 
        {
            # Error when logging to console
            $exceptionDetails = "Exception: " + $_.Exception.Message + "HResult: " + $_.Exception.HResult
            $message = "Error when logging to consloe." 
            Write-Host $message $exceptionDetails -ForegroundColor Red
            SendEventToAppInsights "logging" $message "Failure" $global:utcDate "2" $_.Exception.HResult $_.Exception.Message
            [System.Environment]::Exit(2)
        }
    }
    elseif ($logMode -eq "1")
    {
        Try 
        {
            Write-Host "$global:logDate : $logMessage" -ForegroundColor $textColor
            Add-Content $global:logFile "$global:logDate : $logLevel : $logMessage"
        }
        Catch 
        {
            # Error when logging to console and file
            $exceptionDetails = "Exception: " + $_.Exception.Message + "HResult: " + $_.Exception.HResult
            $message = "Error when logging to consloe and file." 
            Write-Host $message $exceptionDetails -ForegroundColor Red
            SendEventToAppInsights "logging" $message "Failure" $global:utcDate "3" $_.Exception.HResult $_.Exception.Message            
            [System.Environment]::Exit(3)
        }
    }
    elseif ($logMode -eq "2")
    {
        Try 
        {
            Add-Content $global:logFile "$global:logDate : $logLevel : $logMessage"
        }
        Catch 
        {
            # Error when logging to file
            $exceptionDetails = "Exception: " + $_.Exception.Message + "HResult: " + $_.Exception.HResult
            $message = "Error when logging to file." 
            Write-Host $message $exceptionDetails -ForegroundColor Red
            SendEventToAppInsights "logging" $message "Failure" $global:utcDate "4" $_.Exception.HResult $_.Exception.Message            
            [System.Environment]::Exit(4)
        }
    }
    else
    {
        Try 
        {
            Write-Host "$global:logDate : $logMessage" -ForegroundColor $textColor
            Add-Content $global:logFile "$global:logDate : $logLevel : $logMessage"
        }
        Catch 
        {
            # Error when logging to console and file
            $exceptionDetails = "Exception: " + $_.Exception.Message + "HResult: " + $_.Exception.HResult
            $message = "Error when logging to consloe and file." 
            Write-Host $message $exceptionDetails -ForegroundColor Red
            SendEventToAppInsights "logging" $message "Failure" $global:utcDate "5" $_.Exception.HResult $_.Exception.Message 
            [System.Environment]::Exit(5)
        }
    }
}

function ConfigureAppInsights
{
    Try
    {
        $AI = "$global:scriptRoot\Microsoft.ApplicationInsights.dll"
        [Reflection.Assembly]::LoadFile($AI)

        $InstrumentationKey = "AIF-0f3e00af-cf3f-45ef-93d0-ba8d31ec0c21"
        [Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration]::Active.TelemetryChannel.EndpointAddress = "https://vortex.data.microsoft.com/collect/v1"
        [Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration]::Active.InstrumentationKey = $InstrumentationKey
        $global:AppInsightsTelClient = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
        $global:appInsightsConfigured = $true
    }
    Catch
    {
        $exception = "Exception: " + $_.Exception.Message + " HResult: " + $_.Exception.HResult
        Log "ConfigureAppInsights failed with unexpected exception. Data will not be sent to AppInsights. This is optional and does not affect the onboarding process. The script will continue. $exception"
    }           
}

function SendEventToAppInsights($operation, $message, $eventType, $eventDate, $errorCode, $exceptionHresult, $exceptionMessage)
{
    if($global:appInsightsConfigured -eq $true)
    {
        Try
        {
            $telEvent = New-Object "Microsoft.ApplicationInsights.DataContracts.EventTelemetry"
            $telEvent.Name = "UAConfigScript"
            $telEvent.Properties["ComponentName"] = "UAConfigScript"
            $telEvent.Properties["Version"] = [string]$global:scriptVersion
            $telEvent.Properties["OSVersion"] = [string]$global:osVersion
            $telEvent.Properties["Operation"] = [string]$operation
            $telEvent.Properties["RunID"] = [string]$global:runGuid
            $telEvent.Properties["RunMode"] = [string]$runMode
            $telEvent.Properties["CommercialID"] = [string]$commercialIDValue
            $telEvent.Properties["SqmID"] = [string]$global:sClientId
            $telEvent.Properties["DeviceNameOptIn"] = [string]$DeviceNameOptIn
            
            if($DeviceNameOptIn -eq "true")
            {
                $telEvent.Properties["DeviceName"] = [string]$global:machineName
            }
            
            $telEvent.Properties["AllowIEData"] = [string]$AllowIEData
            $telEvent.Properties["IEOptInLevel"] = [string]$IEOptInLevel
            $telEvent.Properties["Proxy"] = [string]$ClientProxy
            $telEvent.Properties["Type"] = [string]$eventType
            $telEvent.Properties["DateTime"] = $eventDate
            $telEvent.Properties["Message"] = [string]$message
            $telEvent.Properties["ErrorCode"] = [string]$errorCode
            $telEvent.Properties["ExceptionHResult"] = [string]$exceptionHresult
            $telEvent.Properties["ExceptionMessage"] = [string]$exceptionMessage
            
            # We send the Appraiser version with the last event of the script.
            if($eventType -eq "Failure" -or $eventType -eq "Success")
            {
                $telEvent.Properties["AppraiserVersion"] = [string]$global:appraiserVersion
            }

            $global:AppInsightsTelClient.TrackEvent($telEvent.Name, $telEvent.Properties, $null)
            $global:AppInsightsTelClient.Flush() 
        }
        Catch
        {
            if($global:excepThrownForSendEventToAppInsights -eq $false)
            {
                $exception = "Exception: " + $_.Exception.Message + " HResult: " + $_.Exception.HResult
                Log "SendEventToAppInsights failed with unexpected exception. Data will not be sent to AppInsights. The script will continue. $exception"
                $global:excepThrownForSendEventToAppInsights = $true
            }
        }
    }
}

# Calling the main function
&$main

# ------------------------------------------------------------------------------------------------
# END