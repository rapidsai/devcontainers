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
    $repo
)

Write-Output "${repo}:${edition}-cuda-${cudaVersion}-cl-${clVersion}"
