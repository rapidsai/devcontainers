# Fetch git
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe" -OutFile "C:\git_installer.exe" -UseBasicParsing
Start-Process -NoNewWindow -Wait -FilePath "C:\git_installer.exe" -ArgumentList "/S /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
Remove-Item "C:\git_installer.exe"

$ENV:PATH = "C:\Program Files\Git\bin;$ENV:PATH"

