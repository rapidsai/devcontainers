mkdir -p "$(Get-Location)\jq"

Invoke-WebRequest -Uri "https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-windows-amd64.exe" -OutFile "$(Get-Location)\jq\jq.exe" -UseBasicParsing

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\jq"
