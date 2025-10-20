# clVersion, cudaVersion, OS edition, isolation mode
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $clVersion="latest",
    [Parameter(Mandatory=$false)]
    [string]
    $cudaVersion="latest",
    [Parameter(Mandatory=$false)]
    [ValidateSet('windows2019', 'windows2022')]
    [string]
    $edition="windows",
    [Parameter(Mandatory=$false)]
    [ValidateSet('hyperv', 'process')]
    [string]
    $isolation="hyperv",
    [Parameter(Mandatory=$false)]
    [string]
    $repo="local",
    [Parameter(Mandatory=$false)]
    [string]
    $repoVersion="latest",
    [Parameter(Mandatory=$false)]
    [string]
    $syftVer="latest"
)

function TestReturnCode {
    if (-not $?) {
        throw 'Step Failed'
    }
}

Push-location "$PSScriptRoot"

$rootWindowsImage = @{
    "windows2022" = "mcr.microsoft.com/windows/servercore:ltsc2022"
    "windows2019" = "mcr.microsoft.com/windows/servercore:ltsc2019"
}[$edition]

if ($syftVer -eq "latest") {
    $latest = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/anchore/syft/releases/latest"
    $syftVer = $latest.tag_name.TrimStart('v')
}

$syftArch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) { 'windows_arm64' } else { 'windows_amd64' }

try {
    # Source version matrix
    .\vs-version-matrix.ps1

    $vsVer = $vsYearToVer[$vsCompilersToYear[$clVersion]]
    # Override defaults in .env.
    $ENV:IMAGE_NAME="$(.\generate-image-name.ps1 -clVersion $clVersion -cudaVersion $cudaVersion -edition $edition -repo $repo -repoVersion $repoVersion)"
    $ENV:ISOLATION="$isolation"
    $ENV:MSVC_VER="$vsVer"
    $ENV:MSVC_COMPILER_VER="$clVersion"
    $ENV:CUDA_VER="$cudaVersion"
    $ENV:ROOT_IMAGE="$rootWindowsImage"
    $ENV:BUILDKIT_PROGRESS="plain"

    Write-Output "Building $ENV:IMAGE_NAME"
    Write-Output "with args:"
    Write-Output "ENV:IMAGE_NAME         $ENV:IMAGE_NAME"
    Write-Output "ENV:ISOLATION          $ENV:ISOLATION"
    Write-Output "ENV:MSVC_VER           $ENV:MSVC_VER"
    Write-Output "ENV:MSVC_COMPILER_VER  $ENV:MSVC_COMPILER_VER"
    Write-Output "ENV:CUDA_VER           $ENV:CUDA_VER"
    Write-Output "ENV:ROOT_IMAGE         $ENV:ROOT_IMAGE"

    docker build --file .\windows.Dockerfile --tag "$ENV:IMAGE_NAME" --isolation "$ENV:ISOLATION" --build-arg MSVC_VER="$ENV:MSVC_VER" --build-arg MSVC_COMPILER_VER="$ENV:MSVC_COMPILER_VER" --build-arg CUDA_VER="$ENV:CUDA_VER" --build-arg ROOT_IMAGE="$ENV:ROOT_IMAGE" --build-arg SYFT_VER="$syftVer" --build-arg SYFT_ARCH="$syftArch" .\image
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
