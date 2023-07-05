Param(
    [Parameter(Mandatory=$true)]
    [string]
    $msvcVersion,
    [Parameter(Mandatory=$true)]
    [string]
    $cudaVersion="latest",
    [Parameter(Mandatory=$true)]
    [string]
    $edition="windows",
    [Parameter(Mandatory=$true)]
    [string]
    $isolation="hyperv",
    [Parameter(Mandatory=$true)]
    [string]
    $repo
)

$ErrorActionPreference = "Stop"

# Assume this script is launched from repo root.
.\scripts\windows\vs-version-matrix.ps1
$clVerArray = ($vsVerToCompilers[$msvcVersion])


foreach($cl in $clVerArray) {
    $image=$(.\scripts\windows\generate-image-name -clVersion $cl -cudaVersion $cudaVersion -edition $edition -repo $repo)
    Write-Output "Pushing $image"

    docker push $image
}
