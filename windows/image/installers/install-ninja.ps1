Invoke-WebRequest -Uri "https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-win.zip" -OutFile "./ninja.zip" -UseBasicParsing
Expand-Archive .\ninja.zip

$ENV:PATH="$ENV:PATH;$(Get-Location)\ninja"

Remove-Item .\ninja.zip
