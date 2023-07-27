Param(
    [Parameter(Mandatory=$true)]
    [string]
    $cudaVersion
)

$ErrorActionPreference='Stop'

## Make sure the script is local to the directory here.
Push-location "$PSScriptRoot"

## Source and install the below
./installers/install-cuda.ps1 -cudaVersion $cudaVersion
./installers/install-git.ps1
./installers/install-lit.ps1
./installers/install-cmake.ps1
./installers/install-ninja.ps1
./installers/install-sccache.ps1

## Save the current environment without MSVC plugged in
New-Item -ItemType Directory -Path "$HOME" -Name "build-env"

# Filter these non-portable exported environment variables
$envFilter = `
    "COMPUTERNAME","TEMP","TMP","SystemDrive","SystemRoot","USERNAME","USERPROFILE",`
    "APPDATA","LOCALAPPDATA","NUMBER_OF_PROCESSORS","PROCESSOR_ARCHITECTURE",`
    "PROCESSOR_IDENTIFIER","PROCESSOR_LEVEL","PROCESSOR_REVISION","OS"

$ENV:INSTALLED_MSVC_VERSION=$msvcVersion
Get-ChildItem ENV: | Where-Object { $_.Name -notin $envFilter } | Export-CliXml "$HOME\build-env\env-var.clixml"

./installers/clear-temp.ps1

Pop-Location
