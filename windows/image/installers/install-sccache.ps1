
# First install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

scoop install sccache

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Variable "CMAKE_CUDA_COMPILER_LAUNCHER" -Value "sccache"
Set-MachineEnvironmentVariable -Variable "CMAKE_CXX_COMPILER_LAUNCHER" -Value "sccache"
Set-MachineEnvironmentVariable -Variable "CMAKE_C_COMPILER_LAUNCHER" -Value "sccache"
