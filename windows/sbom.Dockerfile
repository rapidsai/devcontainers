# escape=`
ARG BASE_IMAGE

FROM ${BASE_IMAGE}

SHELL ["powershell.exe", "-Command"]

RUN New-Item -ItemType Directory -Path 'C:\sbom' -Force | Out-Null
COPY ["sbom.json", "C:\\sbom\\sbom.json"]
