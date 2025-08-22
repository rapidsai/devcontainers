# Fetch CMake
Invoke-WebRequest -Uri "https://github.com/Kitware/CMake/releases/download/v4.1.0/cmake-4.1.0-windows-x86_64.msi" -OutFile "C:\cmake_installer.msi" -UseBasicParsing
Start-Process -NoNewWindow -Wait -FilePath msiexec -ArgumentList "/i C:\cmake_installer.msi ADD_CMAKE_TO_PATH=All /qn"
Remove-Item "C:\cmake_installer.msi"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Program Files\CMake\bin"
