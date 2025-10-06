$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# Fetch latest Docker CLI (Windows static build) and configure for Docker-out-of-Docker (DooD)
$dockerReleases = "https://download.docker.com/win/static/stable/x86_64/"

Write-Output "Discovering latest Docker CLI release from $dockerReleases"
$resp = Invoke-WebRequest -UseBasicParsing -Uri $dockerReleases
$latest = $resp.Content.Split() | Select-String -Pattern "(docker-[0-9\.]+\.zip)" | ForEach-Object { $_.Matches.Value } | Select-Object -Last 1

if (-not $latest) {
    throw "Could not determine latest Docker release from $dockerReleases"
}

$dockerZipUrl = "${dockerReleases}${latest}"
Write-Output "Downloading Docker CLI: $dockerZipUrl"
Invoke-WebRequest -UseBasicParsing -OutFile "./docker.zip" -Uri "$dockerZipUrl"

# Extract to current working directory; archive contains a top-level 'docker' folder
Expand-Archive .\docker.zip -DestinationPath .
Remove-Item .\docker.zip

. "$PSScriptRoot/envvars.ps1"

# Add extracted docker folder to machine PATH so 'docker.exe' is available
Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\docker"

# Configure default Docker host to the Windows named pipe used by the host engine.
# This enables Docker-out-of-Docker when the host pipe is mounted into the container:
#   -v \\.\pipe\docker_engine:\\.\pipe\docker_engine
Set-MachineEnvironmentVariable -Variable "DOCKER_HOST" -Value "npipe:////./pipe/docker_engine"

Write-Output "Docker CLI installed. Ensure you run containers with the docker named pipe mounted for DooD."

