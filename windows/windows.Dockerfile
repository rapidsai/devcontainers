ARG ROOT_IMAGE

FROM ${ROOT_IMAGE} AS base

SHELL ["powershell.exe"]

ARG CUDA_VER
ARG MSVC_VER
ARG MSVC_COMPILER_VER
ENV MSVC_COMPILER_VER=${MSVC_COMPILER_VER}

ADD ./ /tools
RUN Set-ExecutionPolicy Unrestricted -Scope CurrentUser

RUN /tools/install-compiler.ps1 -msvcVersion $ENV:MSVC_VER -clversion $ENV:MSVC_COMPILER_VER
RUN /tools/install-tools.ps1 -cudaVersion $ENV:CUDA_VER

FROM base AS sbom

ARG SYFT_VER=latest
ARG SYFT_ARCH=windows_amd64

RUN $ErrorActionPreference = 'Stop'; \
    New-Item -ItemType Directory -Path C:\sbom -Force | Out-Null; \
    $zipPath = Join-Path $env:TEMP 'syft.zip'; \
    $extractPath = Join-Path $env:TEMP 'syft'; \
    Invoke-WebRequest -UseBasicParsing -Uri ("https://github.com/anchore/syft/releases/download/v{0}/syft_{0}_{1}.zip" -f $SYFT_VER, $SYFT_ARCH) -OutFile $zipPath; \
    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force; } \
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force; \
    $exePath = Get-ChildItem -Path $extractPath -Recurse -Filter 'syft.exe' | Select-Object -First 1 | ForEach-Object { $_.FullName }; \
    & $exePath scan --scope all-layers --output 'cyclonedx-json@1.6=C:/sbom/sbom.json' dir:C:/; \
    Remove-Item $zipPath -Force; \
    Remove-Item $extractPath -Recurse -Force

FROM base

COPY --from=sbom C:\sbom\sbom.json C:\sbom\sbom.json
