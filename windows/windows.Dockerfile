ARG ROOT_IMAGE

FROM $ROOT_IMAGE

SHELL ["powershell.exe"]

ARG CUDA_VER
ARG MSVC_VER
ARG MSVC_COMPILER_VER
ENV MSVC_COMPILER_VER=${MSVC_COMPILER_VER}

ADD ./ /tools
RUN Set-ExecutionPolicy Unrestricted -Scope CurrentUser

RUN /tools/install-compiler.ps1 -msvcVersion $ENV:MSVC_VER -clversion $ENV:MSVC_COMPILER_VER
RUN /tools/install-tools.ps1 -cudaVersion $ENV:CUDA_VER
