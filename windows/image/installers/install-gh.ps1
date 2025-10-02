Invoke-WebRequest -Uri "https://github.com/cli/cli/releases/download/v2.81.0/gh_2.81.0_windows_amd64.zip" -OutFile "./gh.zip" -UseBasicParsing
Expand-Archive .\gh.zip
Remove-Item .\gh.zip

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\gh\bin"

