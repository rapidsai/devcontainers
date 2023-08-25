
# First install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

scoop install sccache

[System.Environment]::SetEnvironmentVariable('CMAKE_CUDA_COMPILER_LAUNCHER','sccache')
[System.Environment]::SetEnvironmentVariable('CMAKE_CXX_COMPILER_LAUNCHER','sccache')
[System.Environment]::SetEnvironmentVariable('CMAKE_C_COMPILER_LAUNCHER','sccache')
