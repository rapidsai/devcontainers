# Fetch CMake
Invoke-WebRequest -Uri "https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-windows-x86_64.msi" -OutFile "C:\cmake_installer.msi" -UseBasicParsing
Start-Process -NoNewWindow -Wait -FilePath msiexec -ArgumentList "/i C:\cmake_installer.msi ADD_CMAKE_TO_PATH=All /qn"
Remove-Item "C:\cmake_installer.msi"

$ENV:PATH = "C:\Program Files\CMake\bin;$ENV:PATH"
