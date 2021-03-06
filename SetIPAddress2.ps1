﻿#Create the function to set the IPAddress
function Set-StaticIPAddress ($strIPAddress, $strSubnet, $strGateway, $strDNSServer1, $strDNSServer2) {
    $NetworkConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = 'True'"
    $NetworkConfig.EnableStatic($strIPAddress, $strSubnet)
    $NetworkConfig.SetGateways($strGateway, 1)
    $NetworkConfig.SetDNSServerSearchOrder(@($strDNSServer1, $strDNSServer2))
}
$C = $env:COMPUTERNAME

switch ($C) {
    'anc-adm100-prs'{
        $IP = '192.168.41.26'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-adt00-prs'{
        $IP = '192.168.42.39'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ahs100-prs'{
        $IP = '192.168.42.35'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ans101-prs'{
        $IP = '192.168.42.2'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-art339-prs'{
        $IP = '192.168.41.2'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-avc124a-prs'{
        $IP = '192.168.121.10'
        $DG = '192.168.121.1'
        $SM = '255.255.255.224'
        }
    'anc-com105-prs'{
        $IP = '192.168.40.2'
        $DG = '192.168.40.1'
        $SM = '255.255.255.0'
        }
    'anc-ec214-prs'{
        $IP = '192.168.121.34'
        $DG = '192.168.121.33'
        $SM = '255.255.255.224'
        }
    'anc-eib112-prs'{
        $IP = '192.168.42.45'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-eib201g-prs'{
        $IP = '192.168.42.47'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-eib401-prs'{
        $IP = '192.168.42.53'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-fccmp32'{
        $IP = '137.229.183.204'
        $DG = '137.229.183.193'
        $SM = '255.255.255.0'
        }
    'anc-esh125-prs'{
        $IP = '192.168.41.57'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-hsb104-prs'{
        $IP = '192.168.45.2'
        $DG = '192.168.45.1'
        $SM = '255.255.255.0'
        }
    'anc-hsb204-prs'{
        $IP = '192.168.45.9'
        $DG = '192.168.45.1'
        $SM = '255.255.255.0'
        }
    'anc-isb100-prs'{
        $IP = '192.168.44.8'
        $DG = '192.168.44.1'
        $SM = '255.255.255.0'
        }
    'anc-isb312-prs'{
        $IP = '192.168.44.2'
        $DG = '192.168.44.1'
        $SM = '255.255.255.0'
        }
    'anc-isb314-prs'{
        $IP = '192.168.44.4'
        $DG = '192.168.44.1'
        $SM = '255.255.255.0'
        }
    'anc-isb315-prs'{
        $IP = '192.168.44.6'
        $DG = '192.168.44.1'
        $SM = '255.255.255.0'
        }
    'anc-lib103-prs'{
        $IP = '192.168.41.6'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-lib201-prs'{
        $IP = '192.168.41.11'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-lib105-prs'{
        $IP = '192.168.41.13'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-isb302k-prs'{
        $IP = '192.168.41.19'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-rh106-prs'{
        $IP = '192.168.42.15'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-rh108-prs'{
        $IP = '192.168.42.17'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-smh105-prs'{
        $IP = '192.168.42.19'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-smh110-prs'{
        $IP = '192.168.42.21'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-smh115f-prs'{
        $IP = '192.168.42.27'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-smh118-prs'{
        $IP = '192.168.42.29'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ssb170-prs'{
        $IP = '192.168.41.4'
        $DG = '192.168.41.1'
        $SM = '255.255.255.0'
        }
    'anc-su211-prs'{
        $IP = '192.168.42.32'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-uc119-prs'{
        $IP = '192.168.43.11'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc123a-prs'{
        $IP = '192.168.43.9'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc126-prs'{
        $IP = '192.168.43.2'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc133-prs'{
        $IP = '192.168.43.4'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc134-prs'{
        $IP = '192.168.43.6'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc145-prs'{
        $IP = '192.168.43.43'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-uc150-prs'{
        $IP = '192.168.43.15'
        $DG = '192.168.43.1'
        $SM = '255.255.255.0'
        }
    'anc-ecb201-prs'{
        $IP = '192.168.42.4'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ecb202-prs'{
        $IP = '192.168.42.6'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ecb203-prs'{
        $IP = '192.168.42.8'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ecb206-prs'{
        $IP = '192.168.42.10'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    'anc-ecb209-prs'{
        $IP = '192.168.42.12'
        $DG = '192.168.42.1'
        $SM = '255.255.255.0'
        }
    #'anc-adm100-prs'{
        #$IP = '192.168.41.26'
       # $DG = '192.168.41.1'
       # $SM = '255.255.255.0'
       # }
}

#Write-Host $IP
#Write-Host $DG
#Write-Host $SM




    #Run the function to set the static IP Address
    Set-StaticIPAddress $IP $SM $DG "137.229.138.85" "137.229.138.94"


