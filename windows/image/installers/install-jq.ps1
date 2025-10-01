mkdir -p "$(Get-Location)\jq"

Invoke-WebRequest -Uri "https://github.com/ninja-build/ninja/releases/download/v1.13.1/ninja-win.zip" -OutFile "$(Get-Location)\jq\jq.exe" -UseBasicParsing

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\jq"
