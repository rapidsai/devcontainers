Param(
    [Parameter(Mandatory=$true)]
    [string]
    $clVersion,
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
    $repo,
    [Parameter(Mandatory=$false)]
    [string]
    $repoVersion="latest"
)

function TestReturnCode {
    if (-not $?) {
        throw 'Step Failed'
    }
}

$ErrorActionPreference = "Stop"

# Assume this script is launched from repo root.

$image=$(.\windows\generate-image-name.ps1 -clVersion $clVersion -cudaVersion $cudaVersion -edition $edition -repo $repo -repoVersion $repoVersion)
Write-Output "Testing $image"

docker run --mount type=bind,src="$(Get-Location)\.github\actions\test-windows-image",dst="C:\test" $image powershell "C:\test\image-test.ps1"
TestReturnCode
