# msvcVersion, cudaVersion, OS edition, isolation mode
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $clVersion,
    [Parameter(Mandatory=$true)]
    [string]
    $cudaVersion,
    [Parameter(Mandatory=$true)]
    [string]
    $edition,
    [Parameter(Mandatory=$true)]
    [string]
    $repo,
    [Parameter(Mandatory=$false)]
    [string]
    $prefix=""
)

Write-Output "${repo}:${prefix}cuda${cudaVersion}-cl${clVersion}-${edition}"
