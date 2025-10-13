Param(
    [Parameter(Mandatory = $true)]
    [string]
    $cudaVersion
)

$ErrorActionPreference = 'Stop'

## Make sure the script is local to the directory here.
Push-location "$PSScriptRoot"

## Source and install the below
./installers/install-cuda.ps1 -cudaVersion $cudaVersion
./installers/install-git.ps1
./installers/install-zstd.ps1
./installers/install-gh.ps1
./installers/install-jq.ps1
./installers/install-lit.ps1
## Must be after lit installation for pip
./installers/install-clang-format.ps1
./installers/install-cmake.ps1
./installers/install-ninja.ps1
./installers/install-sccache.ps1
./installers/install-tbb.ps1
./installers/install-docker.ps1
./installers/install-pyenv-win.ps1

./installers/clear-temp.ps1

Pop-Location
