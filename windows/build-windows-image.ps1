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
    $repoVersion="latest"
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

    docker build --file .\windows.Dockerfile --tag "$ENV:IMAGE_NAME" --isolation "$ENV:ISOLATION" --build-arg MSVC_VER="$ENV:MSVC_VER" --build-arg MSVC_COMPILER_VER="$ENV:MSVC_COMPILER_VER" --build-arg CUDA_VER="$ENV:CUDA_VER" --build-arg ROOT_IMAGE="$ENV:ROOT_IMAGE" .\image
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}

$syftVersion = "1.32.0"
$arch = switch ($env:PROCESSOR_ARCHITECTURE.ToLower()) {
    "amd64" { "windows_amd64" }
    "arm64" { "windows_arm64" }
    default { throw "Unsupported PROCESSOR_ARCHITECTURE '$env:PROCESSOR_ARCHITECTURE'" }
}
$syftZipName  = "syft_${syftVersion}_${arch}.zip"
$syftDownload = "https://github.com/anchore/syft/releases/download/v$syftVersion/$syftZipName"
$tempRoot    = Join-Path $env:TEMP ("sbom-" + [guid]::NewGuid())
$syftArchive = Join-Path $tempRoot $syftZipName
$sbomJson    = Join-Path $tempRoot "sbom.json"
$contextDir  = Join-Path $tempRoot "context"
New-Item -ItemType Directory -Path $tempRoot, $contextDir | Out-Null

try {
    Invoke-WebRequest `
        -Uri $syftDownload `
        -OutFile $syftArchive `
        -UseBasicParsing
    Expand-Archive -Path $syftArchive -DestinationPath $tempRoot -Force

    $syftExe = Get-ChildItem -Path $tempRoot -Filter syft.exe -Recurse |
               Select-Object -First 1 |
               ForEach-Object FullName
    if (-not $syftExe) {
        throw "syft.exe not found after extracting $syftZipName"
    }

    & $syftExe `
        "docker:$ENV:IMAGE_NAME" `
        --scope all-layers `
        --source-name "$ENV:IMAGE_NAME" `
        "--output" "cyclonedx-json@1.6=$sbomJson"

    Copy-Item -Path $sbomJson -Destination (Join-Path $contextDir "sbom.json")
    Copy-Item -Path (Join-Path $PSScriptRoot "sbom.Dockerfile") -Destination (Join-Path $contextDir "Dockerfile")

    docker build `
        --file (Join-Path $contextDir "Dockerfile") `
        --build-arg BASE_IMAGE=$ENV:IMAGE_NAME `
        --tag $ENV:IMAGE_NAME `
        $contextDir
}
finally {
    Remove-Item -Path $tempRoot -Recurse -Force
}
