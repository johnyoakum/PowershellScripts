﻿ #Get Logged On User and place into TS Variable, if the TS was initiated by a user
 #Most of code to get the user was stolen from: https://gallery.technet.microsoft.com/scriptcenter/0e43993a-895a-4afe-a2b2-045a5146048a
 #Modified by @gwblok (GARYTOWN.COM)
 #This script is designed to be used with the SetInfo Script for WaaS https://garytown.com/collect-osd-ipu-info-with-hardware-inventory

 $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
 if ($tsenv.Value("_SMSTSUserStarted") -eq "True")
            {