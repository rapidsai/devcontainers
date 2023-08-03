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
    [alias ("r", "repo")]
    [string[]]
    $repos,
    [Parameter(Mandatory=$false)]
    [string]
    $repoVersion="latest",
    [switch]
    [alias ("n")]
    $dryrun
)

if ($dryrun) {
    function Dry-Run {
        Write-Warning "$args"
    }
}
else {
    function Dry-Run {
        Invoke-Expression "$args"
    }
}

$ErrorActionPreference = "Stop"

# Assume this script is launched from repo root.
.\scripts\windows\vs-version-matrix.ps1
$clVerArray = ($vsVerToCompilers[$msvcVersion])

Write-Output "Pushing to repositories: [$repos]"
$baserepo, $repos = $repos

# Push to the base repo first, then push to other repos
foreach($cl in $clVerArray) {
    $baseimage=$(.\scripts\windows\generate-image-name -clVersion $cl -cudaVersion $cudaVersion -edition $edition -repo $baserepo -repoVersion $repoVersion)
    Dry-Run docker push $baseimage

    foreach($repo in $repos) {
        $image=$(.\scripts\windows\generate-image-name -clVersion $cl -cudaVersion $cudaVersion -edition $edition -repo $repo -repoVersion $repoVersion)
        Dry-Run docker tag $baseimage $image
        Dry-Run docker push $image
    }
}
