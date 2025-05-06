param(
    [string]
    $vcver="latest"
)

. "$PSScriptRoot/envvars.ps1"

$MSBuildPath = "C:\msbuild"

$MSBuildPathMap = @{
    "14.11"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.12"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.13"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.14"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.15"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.16"="$MSBuildPath\15\VC\Auxiliary\Build"
    "14.20"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.21"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.22"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.23"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.24"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.25"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.26"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.27"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.28"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.28.29333"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.28.29910"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.29"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.29.30037"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.29.30133"="$MSBuildPath\16\VC\Auxiliary\Build"
    "14.30"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.31"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.32"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.33"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.34"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.35"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.36"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.37"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.38"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.39"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.40"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.41"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.42"="$MSBuildPath\17\VC\Auxiliary\Build"
    "14.43"="$MSBuildPath\17\VC\Auxiliary\Build"
    "latest"="$MSBuildPath\$ENV:INSTALLED_MSVC_VERSION\VC\Auxiliary\Build"
}

$BuildPath = $MSBuildPathMap[$vcver]
Write-Output "Loading VC from: $BuildPath"

# Filter these non-portable exported environment variables
$envFilter = `
    "COMPUTERNAME","TEMP","TMP","SystemDrive","SystemRoot","USERNAME","USERPROFILE",`
    "APPDATA","LOCALAPPDATA","NUMBER_OF_PROCESSORS","PROCESSOR_ARCHITECTURE",`
    "PROCESSOR_IDENTIFIER","PROCESSOR_LEVEL","PROCESSOR_REVISION","OS","Platform"

# If a specific version has been requested provide that rather than grab default
Push-Location "$BuildPath"
$cmd="vcvars64.bat & set"
if ($vcver -ne "latest") {
    $cmd="vcvars64.bat -vcvars_ver=$vcver & set"
}

Set-MachineEnvironmentVariable -Variable "INSTALLED_MSVC_VERSION" -Value "$msvcVersion"

cmd /c $cmd | foreach {
    if ($_ -match "=") {
        $v = $_.split("=");
        if ($v[0] -notin $envFilter) {
            Set-MachineEnvironmentVariable -Append -Variable "$($v[0])" -Value "$($v[1])"
        }
    }
}

Pop-Location

# Update PATH from machine env
Write-MachineEnvironmentVariable -Variable "PATH"

# Stupid, but can make CMake happy if it is needed
Set-MachineEnvironmentVariable -Variable "CC_FP" -Value "$($(get-command cl).Source.Replace("\","/"))"

Write-Host "`nVisual Studio Command Prompt variables set." -ForegroundColor Yellow
Write-Host "Use 'cl' or `$CC_FP as shortcut for CMake: $CC_FP" -ForegroundColor Yellow
