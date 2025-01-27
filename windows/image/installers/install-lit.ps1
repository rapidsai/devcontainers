Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.13.1/python-3.13.1-amd64.exe" -OutFile ./python_installer.exe -UseBasicParsing
Start-Process -Wait -FilePath .\python_installer.exe -ArgumentList "/quiet Include_test=0 InstallAllUsers=1 TargetDir=C:\Python"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Python"
Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Python\Scripts"

# Immediately update envvars
Write-MachineEnvironmentVariable -Variable "PATH"

python -m pip install --upgrade pip
python -m pip install wheel
python -m pip install psutil
python -m pip install lit

Remove-Item .\python_installer.exe
