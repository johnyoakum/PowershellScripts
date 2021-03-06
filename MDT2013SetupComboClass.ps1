# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

Write-Host "PowerShell runs elevated, OK, continuing..." -ForegroundColor Green
Write-Host ""

# Check for ISO folder
Write-Host "Checking for ISO folder"
If (Test-Path 'C:\ISO'){
    Write-Warning "ISO folder found in C:\, aborting... Please delete folder and run script again."
    Break
    } 
Else {
    Write-Host "ISO folder not found, OK, continuing..." -ForegroundColor Green
    Write-Host ""
}

# Check Windows Version
Write-Host "Checking for Windows version"
$OSCaption = (Get-WmiObject win32_operatingsystem).caption
If ($OSCaption -notlike "Microsoft Windows Server 2012 R2*")
{
    Write-Warning "Oupps, you really need to have Windows Server 2012 R2"
    Write-Warning "Aborting script..."
    Break
}

Write-Host "You are running Windows Server 2012 R2, OK, continuing..." -ForegroundColor Green
Write-Host ""

# Check for pending reboot
Write-Host "Checking for pending reboot"
Function Check-PendingReboot{

    $computername = $env:COMPUTERNAME

    # Connection to local or remote Registry
    $RegConnection = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$computername)

    # Query the Component Based Servicing Registry Key
    $RegSubKeysCBS = $RegConnection.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames()
    $CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"

    # Query the Windows Update Auto Update Registry Key
    $RegWUAU = $RegConnection.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
    $RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
    $WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
						
    # Query the PendingFileRenameOperations Registry Key
    $RegSubKeySM = $RegConnection.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
    $RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)

    # Closing registry connection
    $RegConnection.Close()

    # If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
    If ($RegValuePFRO)
	    {
		    $PendFileRename = $true

	    }

    # Check if any of the variables are true
    If ($CBSRebootPend -or $WUAURebootReq -or $PendFileRename)
	    {
            Write-Warning "There is a pending reboot"
            Write-Warning "Please reboot the server, then login and run the script again"
            Break
	    }
						
    Else 
        {
            Write-Host "No reboot pending, OK, continuing" -ForegroundColor Green

        }
}

. Check-PendingReboot

# Check for any running VMs
Write-Host "Checking for any running VMs"
if ((Get-VM | where State -eq running).Count -gt 0)
{
write-warning "You have VMs running, turn them off before continuing..."
Break
}

Write-Host "No running VMs, OK, continuing..." -ForegroundColor Green
Write-Host ""


# Check memory on the host - Minimum is 16 GB (32 GB recommended)
Write-Host "Checking memory on the host - Minimum is 16 GB (32 GB recommended)"
$NeededMemory = 16 #GigaBytes
$Memory = get-wmiobject Win32_ComputerSystem 
$MemoryInGB = [math]::round($Memory.TotalPhysicalMemory/1GB, 0)

if($MemoryInGB -lt $NeededMemory){
    
    Write-Warning "Oupps, you need at least $NeededMemory GB of memory"
    Write-Warning "Available memory on the host is $MemoryInGB GB"
    Write-Warning "Aborting script..."
    Break
}

Write-Host "Machine has $MemoryInGB GB memory, OK, continuing..." -ForegroundColor Green
Write-Host ""

# Check for classroom VMs and ISO (archived in the MDT2013.vhdx file)
Write-Host "Checking for MDT2013.vhdx archive (classroom VMs and ISO files)"
If (Test-Path .\MDT2013.vhdx){
    Write-Host "MDT2013.vhdx file found, OK, continuing..." -ForegroundColor Green
    Write-Host ""
    } 
Else {
    Write-Warning "Oupps, MDT2013.vhdx file not found, verify that you installed 7-Zip 9.20 and extracted the 7-Zip archive to the C:\Classroom\Setup folder"
    Break
}

# Check for DA LAB GPO
Write-Host "Checking DA LAB GPO"
If (Test-Path .\Setup\DA-LAB-GPO\manifest.xml){
    Write-Host "manifest.xml file found, OK, continuing..." -ForegroundColor Green
    Write-Host ""
    } 
Else {
    Write-Warning "Oupps, manifest.xml file not found"
    Break
}



# Check free space on C: - Minimum is 150 GB
$NeededFreeSpace = 150 #GigaBytes
$Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 
$FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
Write-Host "Checking free space on C: - Minimum is $NeededFreeSpace GB"

if($FreeSpace -lt $NeededFreeSpace){
    
    Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
    Write-Warning "Available free space on C: is $FreeSpace GB"
    Write-Warning "Aborting script..."
    Break
}

Write-Host "Disk has $FreeSpace GB free space, OK, continuing..." -ForegroundColor Green
Write-Host ""

# Check for Hyper-V Virtual Machine Management Service
Write-Host "Checking for Hyper-V Virtual Machine Management Service"
$Service = Get-Service -Name "Hyper-V Virtual Machine Management"
if ($Service.Status -ne "Running"){
    Write-Warning "Hyper-V Virtual Machine Management service not started, aborting script..."
    Break
}

Write-Host "Hyper-V Virtual Machine Management service running, OK, continuing..." -ForegroundColor Green
Write-Host ""

# Checks completed, starting configuration block

# Add Data DeDuplication
Write-Host "Adding Data DeDuplication"
Add-WindowsFeature -Name FS-Data-Deduplication | Out-Null
Write-Host "Data DeDuplication added" -ForegroundColor Green
Write-Host ""

# If you need to get the scriptpath from ISE
# $ISEScriptRoot = split-path -parent $psISE.CurrentFile.Fullpath
# $VHDXFile = "$ISEScriptRoot\MDT2013.vhdx"

# Mount the VHDX file
$VHDXFile = "$PSScriptRoot\MDT2013.vhdx"
Mount-DiskImage -ImagePath $VHDXFile -Access ReadOnly

# Get the drive letter
$VHDXDisk = Get-DiskImage -ImagePath $VHDXFile | Get-Disk -Verbose
$VHDXDiskNumber = [string]$VHDXDisk.Number
$VHDXDrive = Get-Partition -DiskNumber $VHDXDiskNumber
$VHDXVolume = [string]$VHDXDrive.DriveLetter+":"

#Copy VMs
Write-Host "Copying LAB Files (about 100 GB), this will take a while..."
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-CM01 C:\VMS\OSD-SC2012R2-CM01 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-DC01 C:\VMS\OSD-SC2012R2-DC01 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-MDT01 C:\VMS\OSD-SC2012R2-MDT01 -Recurse
#Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-MDT02 C:\VMS\OSD-SC2012R2-MDT02 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-OR01 C:\VMS\OSD-SC2012R2-OR01 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-PC0001 C:\VMS\OSD-SC2012R2-PC0001 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-PC0002 C:\VMS\OSD-SC2012R2-PC0002 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-PC0003 C:\VMS\OSD-SC2012R2-PC0003 -Recurse
Copy-Item $VHDXVolume\VMS\OSD-SC2012R2-PC0004 C:\VMS\OSD-SC2012R2-PC0004 -Recurse
Copy-Item $VHDXVolume\ISO C:\ISO -Recurse
Write-Host "LAB Files copied." -ForegroundColor Green
Write-Host ""

# Unmount the VHDX
Dismount-DiskImage -ImagePath $VHDXFile -Verbose

 # Import the Virtual Machines
Write-Host "Importing the virtual machines"
get-childitem "C:\VMS\OSD*" -recurse -filter *.xml | ForEach-Object {Import-VM -Path $_.FullName} | Out-Null
Start-Sleep -Seconds 10
Write-Host "Virtual machines imported." -ForegroundColor Green
Write-Host ""

# Rename VMs
#Rename-VM -Name OSD-SC2012R2-CM01 -NewName CM01
#Rename-VM -Name OSD-SC2012R2-DC01 -NewName DC01
#Rename-VM -Name OSD-SC2012R2-MDT01 -NewName MDT01
#Rename-VM -Name OSD-SC2012R2-MDT02 -NewName MDT02
#Rename-VM -Name OSD-SC2012R2-OR01 -NewName OR01
#Rename-VM -Name OSD-SC2012R2-PC0001 -NewName PC0001
#Rename-VM -Name OSD-SC2012R2-PC0002 -NewName PC0002
#Rename-VM -Name OSD-SC2012R2-PC0003 -NewName PC0003
#Rename-VM -Name OSD-SC2012R2-PC0004 -NewName PC0004

# Configure the Virtual Machine Memory
Set-VMMemory -VMName OSD-SC2012R2-CM01 -DynamicMemoryEnabled $false -StartupBytes 2048MB
Set-VMMemory -VMName OSD-SC2012R2-DC01 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-MDT01 -DynamicMemoryEnabled $false -StartupBytes 1024MB
#Set-VMMemory -VMName OSD-SC2012R2-MDT02 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-OR01 -DynamicMemoryEnabled $false -StartupBytes 2048MB
Set-VMMemory -VMName OSD-SC2012R2-PC0001 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-PC0002 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-PC0003 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-PC0004 -DynamicMemoryEnabled $false -StartupBytes 1024MB

# Update local host file with VM names
Copy-Item .\Setup\hosts C:\Windows\System32\Drivers\etc\ -Force

Write-Host "Starting DC01 VM"
Start-VM -Name OSD-SC2012R2-DC01
Start-Sleep -Seconds 90
Write-Host "DC01 started." -ForegroundColor Green
Write-Host ""

# Set credentials and allow remote administration via PowerShell to all hosts
winrm set winrm/config/client '@{TrustedHosts="*"}' | Out-Null
$Username = 'VIAMONSTRA\Administrator'
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Configure a domain policy allow remote administration
Write-Host "Configure a domain policy allow remote administration"
net use \\DC01\C$ /u:$Username $Password  | Out-Null
Copy-Item .\Setup\DA-LAB-GPO \\DC01\C$\Setup\DA-LAB-GPO -Recurse | Out-Null
Invoke-Command -ComputerName DC01 -Credential $Cred -ScriptBlock {Import-GPO -BackupId 0DF7D695-1EEA-4F38-B77E-A2FA9A46C503 -Path C:\Setup\DA-LAB-GPO -TargetName 'Deployment Artist LAB Policy' -CreateIfNeeded} | Out-Null
Invoke-Command -ComputerName DC01 -Credential $Cred -ScriptBlock {New-GPLink -Name 'Deployment Artist LAB Policy' -Target "dc=corp,dc=viamonstra,dc=com"} | Out-Null
Write-Host "Domain policy configured." -ForegroundColor Green
Write-Host ""

# Start remaining VMs
Write-Host "Starting remaining VMs..."
Start-VM -Name OSD-SC2012R2-CM01 | Out-Null
Start-VM -Name OSD-SC2012R2-MDT01 | Out-Null
#Start-VM -Name OSD-SC2012R2-MDT02 | Out-Null
#Start-VM -Name OSD-SC2012R2-OR01 | Out-Null
Start-VM -Name OSD-SC2012R2-PC0001 | Out-Null
Start-VM -Name OSD-SC2012R2-PC0002 | Out-Null
Start-VM -Name OSD-SC2012R2-PC0003 | Out-Null
Start-VM -Name OSD-SC2012R2-PC0004  | Out-Null
Start-Sleep -Seconds 240
Write-Host "Remaining VMs started." -ForegroundColor Green
Write-Host ""

# Set timezone and rearm the machines
Write-Host "Set timezone and rearm the machines"
$TimeZone = (tzutil /g)  | Out-Null
#Invoke-Command -ComputerName DC01.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName DC01.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName CM01.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName CM01.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName MDT01.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName MDT01.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName MDT02.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
#Invoke-Command -ComputerName MDT02.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName OR01.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
#Invoke-Command -ComputerName OR01.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName PC0001.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName PC0001.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName PC0002.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName PC0002.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName PC0003.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName PC0003.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
#Invoke-Command -ComputerName PC0004.corp.viamonstra.com -Credential $Cred -Script { cscript c:\windows\system32\slmgr.vbs /rearm } | Out-Null
Invoke-Command -ComputerName PC0004.corp.viamonstra.com -Credential $Cred -Script { param($TimeZone) tzutil /s $TimeZone } -Args $TimeZone | Out-Null
Write-Host "Timezone and rearm completed." -ForegroundColor Green
Write-Host ""

# Stop VMs
Write-Host "Stopping the VMs..."
Stop-VM -Name OSD-SC2012R2-CM01 -Force | Out-Null
Stop-VM -Name OSD-SC2012R2-MDT01 -Force | Out-Null
#Stop-VM -Name OSD-SC2012R2-MDT02 -Force | Out-Null
#Stop-VM -Name OSD-SC2012R2-OR01 -Force | Out-Null
Stop-VM -Name OSD-SC2012R2-PC0001 -Force | Out-Null
Stop-VM -Name OSD-SC2012R2-PC0002 -Force | Out-Null
Stop-VM -Name OSD-SC2012R2-PC0003 -Force | Out-Null
Stop-VM -Name OSD-SC2012R2-PC0004 -Force | Out-Null
Start-Sleep -Seconds 90
Write-Host "VMs stopped" -ForegroundColor Green
Write-Host ""

# Restart DC01
Write-Host "Restarting the DC01 VM"
Invoke-Command -ComputerName DC01.corp.viamonstra.com -Credential $Cred -Script { Restart-Computer -Force }
Start-Sleep -Seconds 90
Write-Host "DC01 VM restarted" -ForegroundColor Green
Write-Host ""
 
# Configure the final Virtual Machine Memory
Write-Host "Configure the final Virtual Machine Memory..."
Set-VMMemory -VMName OSD-SC2012R2-MDT01 -DynamicMemoryEnabled $false -StartupBytes 2048MB
#Set-VMMemory -VMName OSD-SC2012R2-MDT02 -DynamicMemoryEnabled $false -StartupBytes 2048MB
Set-VMMemory -VMName OSD-SC2012R2-OR01 -DynamicMemoryEnabled $false -StartupBytes 4096MB
Set-VMMemory -VMName OSD-SC2012R2-PC0001 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-PC0002 -DynamicMemoryEnabled $false -StartupBytes 2048MB
Set-VMMemory -VMName OSD-SC2012R2-PC0003 -DynamicMemoryEnabled $false -StartupBytes 1024MB
Set-VMMemory -VMName OSD-SC2012R2-PC0004 -DynamicMemoryEnabled $false -StartupBytes 1024MB

$Memory = get-wmiobject Win32_ComputerSystem 
$MemoryInGB = [math]::round($Memory.TotalPhysicalMemory/1GB, 0)
if($MemoryInGB -lt 29){

    Write-Host "Setting CM01 memory to 6 GB" -ForegroundColor Green
    Write-Host ""
    Set-VMMemory -VMName OSD-SC2012R2-CM01 -DynamicMemoryEnabled $false -StartupBytes 6144MB

}
Else {
    Write-Host "Setting CM01 memory to 16 GB" -ForegroundColor Green
    Write-Host ""
    Set-VMMemory -VMName OSD-SC2012R2-CM01 -DynamicMemoryEnabled $false -StartupBytes 16384MB

}

# Create blank VMs
Write-Host "Creating a few blank virtual machines"
$VMLocation = "C:\VMs"
$VMNetwork = "Internal"

$VMName = "OSD-SC2012R2-REF001"
$VMMemory = 2048MB
$VMDiskSize = 60GB
New-VM -Name $VMName -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD | Out-Null
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" | Out-Null

$VMName = "OSD-SC2012R2-PC0005"
$VMMemory = 2048MB
$VMDiskSize = 60GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD | Out-Null
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" | Out-Null

$VMName = "OSD-SC2012R2-PC0006"
$VMMemory = 2048MB
$VMDiskSize = 60GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD | Out-Null
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" | Out-Null

$VMName = "OSD-SC2012R2-PC0007"
$VMMemory = 2048MB
$VMDiskSize = 60GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD | Out-Null
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" | Out-Null

$VMName = "OSD-SC2012R2-PC0008"
$VMMemory = 2048MB
$VMDiskSize = 60GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD | Out-Null
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" | Out-Null

# Make sure no VMs have a mounted ISO
Get-VM | Get-VMDvdDrive | Set-VMDvdDrive -Path $null | Out-Null

Write-Host "Virtual machines created." -ForegroundColor Green
Write-Host ""

# Create and share a folder on the host
#Write-Host "Creating and sharing the C:\Setup folder"
#New-Item -Path "C:\Setup" -ItemType directory | Out-Null
#New-SmbShare –Name Setup –Path "C:\Setup" –ChangeAccess EVERYONE | Out-Null
#Write-Host "C:\Setup folder created and shared." -ForegroundColor Green
#Write-Host ""

Write-Host "**************************"
Write-Host "Classroom setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "**************************"
Write-Host ""