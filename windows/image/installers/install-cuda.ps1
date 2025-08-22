Param(
    [Parameter(Mandatory=$false)]
    [string]
    $cudaVersion="12.9.0"
)

# Use System.Version to tokenize version
$version = [Version]$cudaVersion

$major = $version.Major
$minor = $version.Minor
$build = $version.Build

# Minimum build is 0, not -1 as default in case "12.9" is passed
if ($build -lt 0) {
    $build = 0
}

# mmb == major minor build
$mmbVersionTag = "${major}.${minor}.${build}"
# mm = major minor
$mmVersionTag = "${major}.${minor}"

$cudaMajorUri = "${mmbVersionTag}/network_installers/cuda_${mmbVersionTag}_windows_network.exe"
$cudaVersionUrl = "https://developer.download.nvidia.com/compute/cuda/$cudaMajorUri"
$cudaComponents =
    "nvcc_$mmVersionTag",
    "curand_$mmVersionTag",
    "curand_dev_$mmVersionTag",
    "cudart_$mmVersionTag",
    "cupti_$mmVersionTag",
    "nvrtc_$mmVersionTag",
    "nvrtc_dev_$mmVersionTag",
    "nvml_dev_$mmVersionTag",
    "nvtx_$mmVersionTag",
    "cuxxfilt_$mmVersionTag"

if ("${major}" -ge "13") {
    $cudaComponents += "crt_$mmVersionTag"
}

Write-Output "Installing CUDA Components: ${cudaComponents}"

Invoke-WebRequest -Uri "$cudaVersionUrl" -OutFile "./cuda_network.exe" -UseBasicParsing
Start-Process -Wait -PassThru -FilePath .\cuda_network.exe -ArgumentList "-s $cudaComponents"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag\bin"
Set-MachineEnvironmentVariable -Variable "CUDA_PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag"

Remove-Item .\cuda_network.exe
