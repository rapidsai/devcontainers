Param(
    [Parameter(Mandatory = $false)]
    [string]
    $cudaVersion = "12.9.0"
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

# Keep the following list sorted.
$cudaComponents = @(
    "cublas_$mmVersionTag",
    "cublas_dev_$mmVersionTag",
    "cudart_$mmVersionTag",
    "cuobjdump_$mmVersionTag",
    "cupti_$mmVersionTag",
    "curand_$mmVersionTag",
    "curand_dev_$mmVersionTag",
    "cusparse_$mmVersionTag",
    "cusparse_dev_$mmVersionTag",
    "cuxxfilt_$mmVersionTag",
    "nvcc_$mmVersionTag",
    "nvdisasm_$mmVersionTag",
    "nvjitlink_$mmVersionTag",
    "nvml_dev_$mmVersionTag",
    "nvrtc_$mmVersionTag",
    "nvrtc_dev_$mmVersionTag",
    "nvtx_$mmVersionTag",
    "visual_studio_integration_$mmVersionTag"
)

# nvfatbin first appeared as a separate VS component in 12.4.
if ([int]$major -eq 12 -and [int]$minor -ge 4) {
    $cudaComponents += "nvfatbin_$mmVersionTag"
}

# The following components first appeared in 13.0.
if ([int]$major -ge 13) {
    $cudaComponents += "crt_$mmVersionTag"
    $cudaComponents += "nvvm_$mmVersionTag"
    $cudaComponents += "nvptxcompiler_$mmVersionTag"
}

Write-Output "Installing CUDA Components: $($cudaComponents -join ', ')"

Invoke-WebRequest -Uri "$cudaVersionUrl" -OutFile "./cuda_network.exe" -UseBasicParsing

# Combine all subpackages into one space-separated string for the -s argument
$componentArgs = "-s " + ($cudaComponents -join ' ')

Start-Process -Wait -PassThru -FilePath .\cuda_network.exe -ArgumentList $componentArgs

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag\bin"
Set-MachineEnvironmentVariable -Variable "CUDA_PATH" -Value "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$mmVersionTag"

Remove-Item .\cuda_network.exe
