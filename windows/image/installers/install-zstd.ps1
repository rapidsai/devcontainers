Invoke-WebRequest -Uri "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-v1.5.7-win64.zip" -OutFile "./zstd.zip" -UseBasicParsing
Expand-Archive .\zstd.zip
Remove-Item .\zstd.zip

# Remove the versioned subdirectory:
$subdir = Get-ChildItem .\zstd -Directory | Select-Object -First 1
Move-Item "$($subdir.FullName)\*" .\zstd\
Remove-Item $subdir.FullName -Force

. "$PSScriptRoot/envvars.ps1"

Set-MachineEnvironmentVariable -Append -Variable "PATH" -Value "$(Get-Location)\zstd"
