Param(
    [Parameter(Mandatory=$true)]
    [string]
    $msvcVersion,
    [Parameter(Mandatory=$true)]
    [string]
    $cudaVersion="latest",
    [Parameter(Mandatory=$true)]
    [string]
    $repo
)

$ErrorActionPreference = "Stop"

# Assume this script is launched from repo root.
.\scripts\windows\vs-version-matrix.ps1
$clVerArray = $vsVerToCompilers[$msvcVersion]

foreach ($cl in $clVerArray) {
    .\scripts\windows\make-image-manifest -clVersion $cl -cudaVersion $cudaVersion -repo $repo
}
