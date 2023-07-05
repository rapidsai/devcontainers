# msvcVersion, cudaVersion, OS edition, isolation mode
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $clVersion="latest",
    [Parameter(Mandatory=$false)]
    [string]
    $cudaVersion="latest",
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

try {
    $image_name_2019="$(.\generate-image-name.ps1 -clVersion $clVersion -cudaVersion $cudaVersion -edition "windows-2019" -repo $repo)"
    $image_name_2022="$(.\generate-image-name.ps1 -clVersion $clVersion -cudaVersion $cudaVersion -edition "windows-2022" -repo $repo)"

    $manifest_name="${repo}:windows-cuda-${cudaVersion}-cl-${clVersion}"

    docker manifest rm $manifest_name
    docker manifest create $manifest_name $image_name_2019 $image_name_2022
    docker manifest push $manifest_name
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
