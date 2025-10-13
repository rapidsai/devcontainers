$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# Install pyenv-win using the official installer script
Invoke-WebRequest -UseBasicParsing -Uri `
    "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" `
    -OutFile "./install-pyenv-win.ps1"

& "./install-pyenv-win.ps1"

. "$PSScriptRoot/envvars.ps1"

# Ensure PATH includes pyenv shims and bin for machine scope so pyenv is available
Set-MachineEnvironmentVariable -Append `
    -Variable "PATH" `
    -Value "$env:USERPROFILE\\.pyenv\\pyenv-win\\bin"

Set-MachineEnvironmentVariable -Append `
    -Variable "PATH" `
    -Value "$env:USERPROFILE\\.pyenv\\pyenv-win\\shims"


