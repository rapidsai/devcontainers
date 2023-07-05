Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.7/python-3.10.7-amd64.exe" -OutFile ./python_installer.exe -UseBasicParsing
Start-Process -Wait -FilePath .\python_installer.exe -ArgumentList "/quiet Include_test=0 InstallAllUsers=1 TargetDir=C:\Python"

$ENV:PATH = "C:\Python;$ENV:PATH"
$ENV:PATH = "C:\Python\Scripts;$ENV:PATH"

python -m pip install wheel
python -m pip install lit

Remove-Item .\python_installer.exe
