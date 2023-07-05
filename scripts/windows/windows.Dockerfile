ARG ROOT_IMAGE="mcr.microsoft.com/windows:ltsc2019"

FROM $ROOT_IMAGE as PreCompilerEnv

SHELL ["powershell.exe"]

ARG CUDA_VER

RUN Set-ExecutionPolicy Unrestricted -Scope CurrentUser
ADD ./ /tools

RUN /tools/install-tools.ps1 -cudaVersion $ENV:CUDA_VER

FROM PreCompilerEnv as BuildEnv

ARG MSVC_VER
ARG MSVC_COMPILER_VER

ENV MSVC_COMPILER_VER=${MSVC_COMPILER_VER}
RUN /tools/install-compiler.ps1 -msvcVersion $ENV:MSVC_VER -clversion $ENV:MSVC_COMPILER_VER

ADD installers/build-env.psm1  /Users/ContainerAdministrator/Documents/WindowsPowerShell/Modules/build-env/build-env.psm1
ADD installers/profile.ps1  /Users/ContainerAdministrator/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
