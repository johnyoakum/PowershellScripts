﻿$Packages = Get-CMPackage | Select * | Where {$_.SourceDate -gt '6/12/2019' -and $_.SourceVersion -lt 3}