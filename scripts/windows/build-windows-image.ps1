# msvcVersion, cudaVersion, OS edition, isolation mode
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $clVersion="latest",
    [Parameter(Mandatory=$false)]
    [string]
    $cudaVersion="latest",
    [Parameter(Mandatory=$false)]
    [ValidateSet('windows-2019', 'windows-2022')]
    [string]
    $edition="windows",
    [Parameter(Mandatory=$false)]
    [ValidateSet('hyperv', 'process')]
    [string]
    $isolation="hyperv",
    [Parameter(Mandatory=$false)]
    [string]
    $repo="local"
)

function TestReturnCode {
    if (-not $?) {
        throw 'Step Failed'
    }
}

Push-location "$PSScriptRoot"

$rootWindowsImage = @{
    "windows-2022" = "mcr.microsoft.com/windows/servercore:ltsc2022"
    "windows-2019" = "mcr.microsoft.com/windows/servercore:ltsc2019"
}[$edition]

try {
    # Source version matrix
    .\vs-version-matrix.ps1

    $vsVer = $vsYearToVer[$vsCompilersToYear[$clVersion]]
    # Override defaults in .env.
    $ENV:IMAGE_NAME="$(.\generate-image-name.ps1 -clVersion $clVersion -cudaVersion $cudaVersion -edition $edition -repo $repo)"
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

    # Docker Desktop includes the compose command while CE installations will only have the standalone plugin.

    $compose = "docker compose"
    try {
        docker compose
        TestReturnCode
    }
    catch {
        $compose = "docker-compose.exe"
    }

    Write-Output "Using $compose for building"
    $compose = "$compose -f .\docker-compose.yml build windows"

    Invoke-Expression $compose
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
