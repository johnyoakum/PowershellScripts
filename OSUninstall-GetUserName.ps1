$regexa = '.+Domain="(.+)",Name="(.+)"$' 
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    #$tsenv.CloseProgressDialog()
}
catch
{
	Write-Verbose "Not running in a task sequence."
}


#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPath'))"