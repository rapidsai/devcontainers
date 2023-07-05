$EnvVarBackup = (Resolve-Path -path "$HOME\build-env\env-var.clixml" | % {$_ -replace '\\','/'})
# Import the pre-configured environment
Import-CliXml $EnvVarBackup | % { Set-Item -force -path "env:$($_.Name)" $_.Value }

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
    "latest"="$MSBuildPath\$ENV:INSTALLED_MSVC_VERSION\VC\Auxiliary\Build"
}

function Get-VSDevPrompt {
    param(
        [string]
        $vcver="latest"
    )

    if (Test-Path -Path $EnvVarBackup) {
        Import-CliXml $EnvVarBackup | % { Set-Item -force -path "env:$($_.Name)" $_.Value }
    }

    $BuildPath = $MSBuildPathMap[$vcver]
    Write-Output "Loading VC from: $BuildPath"

    # If a specific version has been requested provide that rather than grab default
    Push-Location "$BuildPath"
    $cmd="vcvars64.bat & set"
    if ($vcver -ne "latest") {
        $cmd="vcvars64.bat -vcvars_ver=$vcver & set"
    }

    cmd /c $cmd |
    foreach {
        if ($_ -match "=") {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
    }
    Pop-Location

    # Stupid, but can make CMake happy if it is needed
    $global:CC_FP = $(get-command cl).Source.Replace("\","/")

    Write-Host "`nVisual Studio Command Prompt variables set." -ForegroundColor Yellow
    Write-Host "Use 'cl' or `$CC_FP as shortcut for Cmake: $CC_FP" -ForegroundColor Yellow
}

Export-ModuleMember -Function Get-VSDevPrompt
