# Fetch git
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe" -OutFile "C:\git_installer.exe" -UseBasicParsing
Start-Process -NoNewWindow -Wait -FilePath "C:\git_installer.exe" -ArgumentList "/S /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
Remove-Item "C:\git_installer.exe"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Program Files\Git\bin"
