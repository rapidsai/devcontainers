# Fetch the rapidsai fork of sccache:
Invoke-WebRequest -Uri "https://github.com/rapidsai/sccache/releases/download/v0.12.0-rapids.10/sccache-v0.12.0-rapids.10-x86_64-pc-windows-msvc.zip" -OutFile "./sccache.zip" -UseBasicParsing
Expand-Archive "./sccache.zip"
Remove-Item "./sccache.zip"

# Remove the versioned subdirectory:
$subdir = Get-ChildItem .\sccache -Directory | Select-Object -First 1
Move-Item "$($subdir.FullName)\*" .\sccache\
Remove-Item $subdir.FullName -Force

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\sccache"
Set-MachineEnvironmentVariable -Variable "CMAKE_CUDA_COMPILER_LAUNCHER" -Value "sccache"
Set-MachineEnvironmentVariable -Variable "CMAKE_CXX_COMPILER_LAUNCHER" -Value "sccache"
Set-MachineEnvironmentVariable -Variable "CMAKE_C_COMPILER_LAUNCHER" -Value "sccache"
