Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('15', '16', '17')]
    [string]
    $msvcVersion,
    [Parameter(Mandatory=$false)]
    [string]
    $clVersion='latest'
)

$ErrorActionPreference='Stop'

Push-location "$PSScriptRoot"

## Install older vs cl
./installers/install-vs.ps1 -msvcVersion $msvcVersion -clVersion $clVersion
./installers/clear-temp.ps1

Pop-Location
