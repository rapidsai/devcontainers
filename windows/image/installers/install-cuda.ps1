Param(
    [Parameter(Mandatory=$false)]
    [string]
    $cudaVersion="12.8.0"
)

# Use System.Version to tokenize version
$version = [Version]$cudaVersion

$major = $version.Major
$minor = $version.Minor
$build = $version.Build

# Minimum build is 0, not -1 as default in case "12.8" is passed
if ($build -lt 0) {
    $build = 0
}

# mmb == major minor build
$mmbVersionTag = "${major}.${minor}.${build}"
# mm = major minor
$mmVersionTag = "${major}.${minor}"

$cudaMajorUri = @{
    "11" = "${mmbVersionTag}/network_installers/cuda_${mmbVersionTag}_win10_network.exe"
    "12" = "${mmbVersionTag}/network_installers/cuda_${mmbVersionTag}_windows_network.exe"
}["$major"]

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
    "nvtx_$mmVersionTag"

Invoke-WebRequest -Uri "$cudaVersionUrl" -OutFile "./cuda_network.exe" -UseBasicParsing
Start-Process -Wait -PassThru -FilePath .\cuda_network.exe -ArgumentList "-s $cudaComponents"

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag\bin"
Set-MachineEnvironmentVariable -Variable "CUDA_PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag"

Remove-Item .\cuda_network.exe
