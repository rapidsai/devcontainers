$TBB_VERSION = "2021.12.0"
Invoke-WebRequest -Uri "https://github.com/oneapi-src/oneTBB/releases/download/v$TBB_VERSION/oneapi-tbb-$TBB_VERSION-win.zip" -OutFile "./tbb.zip" -UseBasicParsing
Expand-Archive .\tbb.zip
Remove-Item .\tbb.zip

$cwd = Get-Location
$LOCAL_TBB_ROOT = "$cwd\tbb\oneapi-tbb-$TBB_VERSION"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$LOCAL_TBB_ROOT\redist\intel64\vc14\"
Set-MachineEnvironmentVariable -Variable "TBB_ROOT" -Value "$LOCAL_TBB_ROOT"
