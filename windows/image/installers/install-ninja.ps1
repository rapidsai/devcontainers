Invoke-WebRequest -Uri "https://github.com/ninja-build/ninja/releases/download/v1.13.1/ninja-win.zip" -OutFile "./ninja.zip" -UseBasicParsing
Expand-Archive .\ninja.zip

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\ninja"

Remove-Item .\ninja.zip
