Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('15', '16', '17', '18')]
    [string]
    $msvcVersion,
    [Parameter(Mandatory = $false)]
    [string]
    $clVersion = "latest"
)

$msvcPath = "C:\msbuild\$msvcVersion"

$vsComponentVersion = @{
    "14.27"  = "14.27"
    "14.28"  = "14.28"
    "14.29"  = "14.29"
    "14.34"  = "14.34.17.4"
    "14.35"  = "14.35.17.5"
    "14.36"  = "14.36.17.6"
    "14.37"  = "14.37.17.7"
    "14.38"  = "14.38.17.8"
    "14.39"  = "14.39.17.9"
    "14.40"  = "14.40.17.10"
    "14.41"  = "14.41.17.11"
    "14.42"  = "14.42.17.12"
    "14.43"  = "14.43.17.13"
    "14.44"  = "14.44.17.14"
    "14.50"  = "14.50.18.0"
    "latest" = "14.50.18.0"
}[$clVersion]

$sdkComponent = @{
    "15" = "Microsoft.VisualStudio.Component.Windows10SDK.17763"
    "16" = "Microsoft.VisualStudio.Component.Windows10SDK.19041"
    "17" = "Microsoft.VisualStudio.Component.Windows11SDK.22621"
    "18" = "Microsoft.VisualStudio.Component.Windows11SDK.22621"
}[$msvcVersion]

$channel = @{
    "15" = "release"
    "16" = "release"
    "17" = "release"
    "18" = "release"
}[$msvcVersion]

$requiredVsComponents = (
    "Microsoft.VisualStudio.Component.VC.${vsComponentVersion}.x86.x64",
    "Microsoft.VisualStudio.Component.VC.${vsComponentVersion}.ATL",
    "Microsoft.VisualStudio.Component.VC.${vsComponentVersion}.ATLMFC",
    "Microsoft.VisualStudio.Component.VC.Llvm.Clang",
    "Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    $sdkComponent
) -replace '^(?<comp>.*)$', ' --add ${comp}' -join ""

Invoke-WebRequest -Uri "https://aka.ms/vs/$msvcVersion/$channel/vs_buildtools.exe" -UseBasicParsing -OutFile .\vs_buildtools.exe
Write-Output "Installing components: $vsComponentString"
Start-Process -NoNewWindow -PassThru -Wait -FilePath .\vs_buildtools.exe -ArgumentList "install --installWhileDownloading --installPath $msvcPath --wait --norestart --nocache --quiet $requiredVsComponents"

# Add VS to the global environment
. "$PSScriptRoot/build-env.ps1" -vcver "$clVersion"

Remove-Item .\vs_buildtools.exe
