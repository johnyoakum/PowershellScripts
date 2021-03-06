﻿function Set-DellAutoOnForSelectDays {
<#
  .Synopsis 
    Configures the system's auto-on capabilities that control individual days
  .Description
    This CmdLet sets the Auto-on to select days and enables or disables the individual days
    to automatically power on the system on a pre fixed .
	If a BIOS password (Admin or System password) is set, supply it using the -Password parameter. 
  .Example
    Set-DellAutoonForSelectDays -Sunday "Enabled" -Monday "Disabled" -password $Password
  .Example
	Set-DellAutoonForSelectDays -Tuesday "Enabled"
  .Example
    Set-DellAutoOnForSelectDays -verbose
#>
[CmdletBinding()]
param(  
    [Alias("Sun")][System.String] $Sunday,
    [Alias("Mon")][System.String] $Monday,
    [Alias("Tue")][System.String] $Tuesday,
    [Alias("Wed")][System.String] $Wednesday,
    [Alias("Thu")][System.String] $Thursday,
    [Alias("Fri")][System.String] $Friday,
    [Alias("Sat")][System.String] $Saturday,
    [Alias("pw")][Parameter(Mandatory=$false)][System.String] $Password
  
 )

 BEGIN { 
        Write-Output "Set-DellAutoOnForSelectDays"
 }
 PROCESS {
    #the process block is called for each item in the pipeline and you can reference it via $_
    #Write-Output "in process"

    $pathToPowerManagement = 'DellSmbios' + ':\' + 'PowerManagement'
    
    
    $isAdminPWSet  = Get-Item -path DellSmbios:\Security\IsAdminPasswordSet
    $issystemPWSet = Get-Item -path DellSmbios:\Security\IsSystemPasswordSet

    if (($isAdminPWSet.CurrentValue -match 'True') -or ($issystemPWSet.CurrentValue -match 'True')) 
    {
        if ([string]::IsNullOrEmpty($Password)){
        Write-Warning "Specify the password using -password."
        return
        }
    }

    
    if ($Password){
        Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -password $Password -ErrorVariable ev
    }
    else{   Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -ErrorVariable ev}

	if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"  
			  return
	}		
	
    if ($PSBoundParameters.ContainsKey('Sunday')) {
        if ($password){    
                Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -ErrorVariable ev}
        
    }
    if ($PSBoundParameters.ContainsKey('Monday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnMon -value $Monday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnMon -value $Monday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Tuesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnTue -value $Tuesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnTue -value $Tuesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Wednesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnWed -value $Wednesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnWed -value $Wednesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Thursday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnThur -value $Thursday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnThur -value $Thursday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Friday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnFri -value $Friday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnFri -value $Friday -ErrorVariable ev}
    }
     if ($PSBoundParameters.ContainsKey('Saturday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnSat -value $Saturday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSat -value $Saturday -ErrorVariable ev}
    }
    if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"    		
	}			
  }
  END{}

  }


# SIG # Begin signature block
# MIIbFQYJKoZIhvcNAQcCoIIbBjCCGwICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkCd2I324kNvJV
# cXRyVRisNACVvbOaR5pBrykHu9NLYqCCCiMwggTCMIIDqqADAgECAhANhLMrA8kb
# dRADSKysMihfMA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3Qg
# TmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBT
# aWduaW5nIENBMB4XDTE2MDEyMDAwMDAwMFoXDTE5MDIxODIzNTk1OVowWjELMAkG
# A1UEBhMCVVMxDjAMBgNVBAgTBVRleGFzMRMwEQYDVQQHEwpSb3VuZCBSb2NrMRIw
# EAYDVQQKFAlEZWxsIEluYy4xEjAQBgNVBAMUCURlbGwgSW5jLjCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAIiB7p20xoJ8RMmDhIKNR/g0X6OhJWWiaLL6
# OY8sCfY9B8BhCOKzCgNQU+g5Jdu5GZ+J7G8S7evlJfhskLH4fhkGYjn4a1sPw/mD
# m/qMaE4n9WLaRourdOIIWgYftCGmjrlpTq7d4rYZ+Oo+iaQTR1OIrnJ7UbV6YYKp
# /buZ3pcrWAB7ox3UDeH/UigGP+QIix5mQrRmQLgZyJkg5V9EB/m2HYmQ+w13VNIf
# adxPklaF1sNMJTRwzKzqZru4N7goue63NAu8COhQ9+c8MIom+VjDVuDR01UY25vQ
# IVJ8Sbk3ORD20Eb6a7ZxVb29Lkn6/cOccCf6tuAe7sd9skZAbJsCAwEAAaOCAV0w
# ggFZMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMCsGA1UdHwQkMCIwIKAeoByG
# Gmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3JsMGEGA1UdIARaMFgwVgYGZ4EMAQQB
# MEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUF
# BwICMBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3N2LnN5bWNk
# LmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3N2LnN5bWNiLmNvbS9zdi5jcnQwHwYD
# VR0jBBgwFoAUljtT8Hkzl699g+8uK8zKt4YecmYwHQYDVR0OBBYEFIb5/xrKh87H
# XzS6cRL1o7LqbfaDMA0GCSqGSIb3DQEBCwUAA4IBAQCFWAnqZghMKytZjfSKt94F
# eB/VfyFl+3tWhPN8SFkXUdIDljd3t5dggtIYAc7TPKfOr8JngIRQmM0lOyj/bzOM
# Chdb8nEbKV4R6krbF423gSVFcYoZsiCoqV2An5OrnnRDPPmgWs5wJvgwk/iGeEYE
# /DQE8J0hWVr4tTQVKRaCBM4DVfK4Z2Mp5BAewp9jxvDS/cuguTQdQP+mtYxmkkXU
# SyTq+olOm8YVPAw0tpRGbZjPdxK2++EIeVrTL7jscqhuMx8d985A4corhmQdZ7Un
# qTurFTSdgqxqZeJiYVFqhp1c9wbCwFuCSTyJiissW+BC4lt+N2oFOSieit7gnmP8
# MIIFWTCCBEGgAwIBAgIQPXjX+XZJYLJhffTwHsqGKjANBgkqhkiG9w0BAQsFADCB
# yjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
# ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJp
# U2lnbiwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxW
# ZXJpU2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0
# aG9yaXR5IC0gRzUwHhcNMTMxMjEwMDAwMDAwWhcNMjMxMjA5MjM1OTU5WjB/MQsw
# CQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNV
# BAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENs
# YXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJeDHgAWryyx0gjE12iTUWAecfbiR7TbWE0jYmq0v1obUfej
# DRh3aLvYNqsvIVDanvPnXydOC8KXyAlwk6naXA1OpA2RoLTsFM6RclQuzqPbROlS
# Gz9BPMpK5KrA6DmrU8wh0MzPf5vmwsxYaoIV7j02zxzFlwckjvF7vjEtPW7ctZlC
# n0thlV8ccO4XfduL5WGJeMdoG68ReBqYrsRVR1PZszLWoQ5GQMWXkorRU6eZW4U1
# V9Pqk2JhIArHMHckEU1ig7a6e2iCMe5lyt/51Y2yNdyMK29qclxghJzyDJRewFZS
# AEjM0/ilfd4v1xPkOKiE1Ua4E4bCG53qWjjdm9sCAwEAAaOCAYMwggF/MC8GCCsG
# AQUFBwEBBCMwITAfBggrBgEFBQcwAYYTaHR0cDovL3MyLnN5bWNiLmNvbTASBgNV
# HRMBAf8ECDAGAQH/AgEAMGwGA1UdIARlMGMwYQYLYIZIAYb4RQEHFwMwUjAmBggr
# BgEFBQcCARYaaHR0cDovL3d3dy5zeW1hdXRoLmNvbS9jcHMwKAYIKwYBBQUHAgIw
# HBoaaHR0cDovL3d3dy5zeW1hdXRoLmNvbS9ycGEwMAYDVR0fBCkwJzAloCOgIYYf
# aHR0cDovL3MxLnN5bWNiLmNvbS9wY2EzLWc1LmNybDAdBgNVHSUEFjAUBggrBgEF
# BQcDAgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgEGMCkGA1UdEQQiMCCkHjAcMRow
# GAYDVQQDExFTeW1hbnRlY1BLSS0xLTU2NzAdBgNVHQ4EFgQUljtT8Hkzl699g+8u
# K8zKt4YecmYwHwYDVR0jBBgwFoAUf9Nlp8Ld7LvwMAnzQzn6Aq8zMTMwDQYJKoZI
# hvcNAQELBQADggEBABOFGh5pqTf3oL2kr34dYVP+nYxeDKZ1HngXI9397BoDVTn7
# cZXHZVqnjjDSRFph23Bv2iEFwi5zuknx0ZP+XcnNXgPgiZ4/dB7X9ziLqdbPuzUv
# M1ioklbRyE07guZ5hBb8KLCxR/Mdoj7uh9mmf6RWpT+thC4p3ny8qKqjPQQB6rqT
# og5QIikXTIfkOhFf1qQliZsFay+0yQFMJ3sLrBkFIqBgFT/ayftNTI/7cmd3/SeU
# x7o1DohJ/o39KK9KEr0Ns5cF3kQMFfo2KwPcwVAB8aERXRTl4r0nS1S+K4ReD6bD
# dAUK75fDiSKxH3fzvc1D1PFMqT+1i4SvZPLQFCExghBIMIIQRAIBATCBkzB/MQsw
# CQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNV
# BAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENs
# YXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQQIQDYSzKwPJG3UQA0isrDIoXzAN
# BglghkgBZQMEAgEFAKCBrDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgWn4fflIL
# AI+v/S4ULV2TAeLRUPAl5YEPYe76IkLwQU8wQAYKKwYBBAGCNwIBDDEyMDCgFoAU
# AEQAZQBsAGwALAAgAEkAbgBjAC6hFoAUaHR0cDovL3d3dy5kZWxsLmNvbSAwDQYJ
# KoZIhvcNAQEBBQAEggEAghwXd9S+laf0oz2KdALDXtDOHqKUKSG3saJ8WzVv+HwA
# xN2ZlBv554s62/dyxjVTK/8VvZONDqM/yokqc8OgDqJpotiQtt9+XHGvvoTKCIdc
# 0RLvQhabeFPr6IRl+PLz3RPqqjLKLzsYixAtaJq30Xie4G3cRzKKBBcNFrpRwCrE
# gGMh3m1yZvCl4bPyg5bqwK+aSEKORm3i4I0ikhlQM5GvEE3gNqxJb890p+mF8Fea
# +qEuGBMVj3hRo6YdQzRrY9C8ykqx4pWvxqia2FiuE5hai3ZT/udiwhFtbGuLioKN
# lTmXMai9fE0j0ePWl3q3C63qX8ZMCpJSZAzeP6ArH6GCDdYwgg3SBgorBgEEAYI3
# AwMBMYINwjCCDb4GCSqGSIb3DQEHAqCCDa8wgg2rAgEDMQ8wDQYJYIZIAWUDBAIB
# BQAwbQYLKoZIhvcNAQkQAQSgXgRcMFoCAQEGCmCGSAGG/W4BBxgwMTANBglghkgB
# ZQMEAgEFAAQgh4QL7QD3CLQdThMMwJiABCvcBI8fiG/uoPYbFpFzLGsCBTEsxKIV
# GA8yMDE4MDUxNTA3MDAwM1qgggqFMIIFADCCA+igAwIBAgIBBzANBgkqhkiG9w0B
# AQsFADCBjzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIElu
# Yy4xMjAwBgNVBAMTKVN0YXJmaWVsZCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAtIEcyMB4XDTExMDUwMzA3MDAwMFoXDTMxMDUwMzA3MDAwMFowgcYxCzAJBgNV
# BAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUw
# IwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTMwMQYDVQQLEypo
# dHRwOi8vY2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8xNDAyBgNV
# BAMTK1N0YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDlkGZL7PlGcakgg77pbL9K
# yUhpgXVObST2yxcT+LBxWYR6ayuFpDS1FuXLzOlBcCykLtb6Mn3hqN6UEKwxwcDY
# av9ZJ6t21vwLdGu4p64/xFT0tDFE3ZNWjKRMXpuJyySDm+JXfbfYEh/JhW300YDx
# UJuHrtQLEAX7J7oobRfpDtZNuTlVBv8KJAV+L8YdcmzUiymMV33a2etmGtNPp99/
# UsQwxaXJDgLFU793OGgGJMNmyDd+MB5FcSM1/5DYKp2N57CSTTx/KgqT3M0WRmX3
# YISLdkuRJ3MUkuDq7o8W6o0OPnYXv32JgIBEQ+ct4EMJddo26K3biTr1XRKOIwSD
# AgMBAAGjggEsMIIBKDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAd
# BgNVHQ4EFgQUJUWBaFAmOD07LSy+zWrZtj2zZmMwHwYDVR0jBBgwFoAUfAwyH6fZ
# MH/EfWijYqihzqsHWycwOgYIKwYBBQUHAQEELjAsMCoGCCsGAQUFBzABhh5odHRw
# Oi8vb2NzcC5zdGFyZmllbGR0ZWNoLmNvbS8wOwYDVR0fBDQwMjAwoC6gLIYqaHR0
# cDovL2NybC5zdGFyZmllbGR0ZWNoLmNvbS9zZnJvb3QtZzIuY3JsMEwGA1UdIARF
# MEMwQQYEVR0gADA5MDcGCCsGAQUFBwIBFitodHRwczovL2NlcnRzLnN0YXJmaWVs
# ZHRlY2guY29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQBWZcr+8z8K
# qJOLGMfeQ2kTNCC+Tl94qGuc22pNQdvBE+zcMQAiXvcAngzgNGU0+bE6TkjIEoGI
# XFs+CFN69xpk37hQYcxTUUApS8L0rjpf5MqtJsxOYUPl/VemN3DOQyuwlMOS6eFf
# qhBJt2nk4NAfZKQrzR9voPiEJBjOeT2pkb9UGBOJmVQRDVXFJgt5T1ocbvlj2xSA
# pAer+rKluYjdkf5lO6Sjeb6JTeHQsPTIFwwKlhR8Cbds4cLYVdQYoKpBaXAko7nv
# 6VrcPuuUSvC33l8Odvr7+2kDRUBQ7nIMpBKGgc0T0U7EPMpODdIm8QC3tKai4W56
# gf0wrHofx1l7MIIFfTCCBGWgAwIBAgIJAO+VwvSA4xuTMA0GCSqGSIb3DQEBCwUA
# MIHGMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2Nv
# dHRzZGFsZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEz
# MDEGA1UECxMqaHR0cDovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRv
# cnkvMTQwMgYDVQQDEytTdGFyZmllbGQgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhv
# cml0eSAtIEcyMB4XDTE3MTExNDA3MDAwMFoXDTIyMTExNDA3MDAwMFowgYcxCzAJ
# BgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxl
# MSQwIgYDVQQKExtTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBMTEMxKzApBgNVBAMT
# IlN0YXJmaWVsZCBUaW1lc3RhbXAgQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQDm730Ku3SPyEahtiafyThSMSvGVFw6JhBrYkQY
# OcH10SjiERRWLn3DD51isWZDIrkxmTdy/zEt2m0qf2odGk7KRPeO7OMlEbeGS4Cc
# 11H7OvxG6VSADFbYTkrgGREeDgFxPA8WzeaJYFVwJq7kcoFSGN797hHOoYsd/GkD
# /iqnEjNfYRUcKdaH9b/Yzjwjte6uba5IeplsNx0eXWU+zy7bff21Qb1HQ0P0VTuY
# CbviRJknhKOZKSGuNhQ9CFDzMQbcbsbyx3+ov/iMaIGp7NHNlk/4hR1rFFmMwPRT
# /m123J8xGpoYBPPMOHyk15bF/1laR3kAr3fhbj0OQoUOUFIBAgMBAAGjggGpMIIB
# pTAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIGwDAWBgNVHSUBAf8EDDAKBggr
# BgEFBQcDCDAdBgNVHQ4EFgQUnc8cgP4K1qL8WBg+p9NUQO7WFGEwHwYDVR0jBBgw
# FoAUJUWBaFAmOD07LSy+zWrZtj2zZmMwgYQGCCsGAQUFBwEBBHgwdjAqBggrBgEF
# BQcwAYYeaHR0cDovL29jc3Auc3RhcmZpZWxkdGVjaC5jb20vMEgGCCsGAQUFBzAC
# hjxodHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvc2ZfaXNz
# dWluZ19jYS1nMi5jcnQwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5L21hc3RlcnN0YXJmaWVsZDJpc3N1aW5n
# LmNybDBQBgNVHSAESTBHMEUGC2CGSAGG/W4BBxcCMDYwNAYIKwYBBQUHAgEWKGh0
# dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcN
# AQELBQADggEBAFJGgfPKVmOa5BUYGkgzgZUHAPDVCxA0oDWH0E5+lQB0DlDHgv5G
# 6O4Ju2dqL9TAJfhRAS0i+PaXwLOWbz/yxZc9jpCNDbVWIRIZdxzXvR7dOSvRPgWF
# xW1Msip51ys9TQV2ybVAyA+CjVwuNOALYWrT2ZhQBEp47lbsLRag4VwYpydVkbfK
# a4Egad+0V0SHQrWxwnMaj/7PT+b8WilhTxTRXNWlxRlQ+9wla5Sqwn5PwafeJwv6
# eGS6nKC00cRPDQ6WDCo46VhOjkmv50J+o93p9LM2hkFuoRMrR5O3D8Zcg1jbab4r
# TDT+f+Wn5eYn9PwbYB7e4WMjRafylm5E3HoxggKbMIIClwIBATCB1DCBxjELMAkG
# A1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUx
# JTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsT
# Kmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIG
# A1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBH
# MgIJAO+VwvSA4xuTMA0GCWCGSAFlAwQCAQUAoIGYMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMTgwNTE1MDcwMDAzWjArBgsqhkiG
# 9w0BCRACDDEcMBowGDAWBBQNXjR81bN5Ps/q5rhg2w9VXb4kpTAvBgkqhkiG9w0B
# CQQxIgQgV7Eqgf1FbmD+dq5xVzc0Wdo2hWjUQPM0GrWQCdJvfMgwDQYJKoZIhvcN
# AQEBBQAEggEAFy0zk5S9iXSd+zzZjayYqPjLawUkIjzv6++oLkzSYzxqNYRxbrUR
# 1PC/nClv8+ZBEWbDS0fBQgbsXxpx50Oa/sCeII4PEHR07RGeHIoqV5tRWezZznQT
# WT0o4nj3vaKRNt1qjCivGeZHM3UP3mmu9p71unhUs3JwVGgR2sP8MHWQJKdD/5JR
# 9Zw/8xbUvq20DyLeLqnaYg6efDo4NlTnWg3LuL/OniGqx4sB8P6r8KMR49hZA64+
# mZIBYfnfjuOKiIhXJc5kNuZ3XprKHMfFBA6w4SVaqbojsnqtjNROQq0z595YJEXQ
# ts0n0y1Rjl0nWqcuTqRw/H+odNz/gkJWTw==
# SIG # End signature block
