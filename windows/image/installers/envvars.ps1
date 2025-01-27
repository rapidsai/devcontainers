function Set-MachineEnvironmentVariable {
    param(
        [switch]
        $Append,
        [string]
        [parameter(Mandatory=$true)]
        $Variable,
        [string]
        [parameter(Mandatory=$true)]
        $Value
    )

    $ProgressPreference = "SilentlyContinue"
    $ErrorActionPreference = "Stop"

    if ($Append) {
        $old = [Environment]::GetEnvironmentVariable("$Variable", [EnvironmentVariableTarget]::Machine)
        if ($old -And $old.Split(';') -icontains "$Value") {
            Write-Warning "Environment variable already configured"
            return
        }
        ## If $old is null because it is empty, it will fallthrough to non-append
        elseif ($old) {
            $Value = "${Value};${old}"
        }
    }

    [Environment]::SetEnvironmentVariable("${Variable}", "${Value}", [EnvironmentVariableTarget]::Machine)

    $check = [Environment]::GetEnvironmentVariable("${Variable}", [EnvironmentVariableTarget]::Machine)
    if ($check -And $check -icontains "${Value}") {
        Write-Warning "Succesfully set ${Variable} = '${Value}'"
        return
    }
    else {
        Write-Error "Failed to set ${Variable} = '${Value}'"
        return
    }

}

function Write-MachineEnvironmentVariable {
    param(
        [string]
        [parameter(Mandatory=$true)]
        $Variable
    )

    $ProgressPreference = "SilentlyContinue"
    $ErrorActionPreference = "Stop"

    $val = [Environment]::GetEnvironmentVariable("${Variable}", [System.EnvironmentVariableTarget]::Machine)
    Set-Item -Path "env:${Variable}" -Value "${val}"

    Write-Warning "Set env:${Variable} to $val"
}
