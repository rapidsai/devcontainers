function TestReturnCode {
    if (-not $?) {
        throw 'Step Failed'
    }
}

$ErrorActionPreference = "Stop"

Push-location "$ENV:TEMP"
try {
    Write-Output "Test Ninja"
    ninja --version
    TestReturnCode

    Write-Output "Test MSVC"
    cl
    TestReturnCode

    Write-Output "Test sccache"
    sccache --version
    TestReturnCode

    Write-Output "int main() {}" > .\test.cpp
    cl .\test.cpp
    TestReturnCode

    Write-Output "Test git"
    git --version
    TestReturnCode

    Write-Output "Test zstd"
    zstd --version
    TestReturnCode

    Write-Output "Test jq"
    jq --version
    TestReturnCode

    Write-Output "Test gh"
    gh --version
    TestReturnCode

    Write-Output "Test CMake"
    cmake --version
    TestReturnCode

    Write-Output "Test NVCC"
    nvcc --version
    TestReturnCode

    # CUDA compilation for unsupported nvcc + msvc combinations might fail. In that case we check for part of the error
    # string emitted by CUDA headers.
    Write-Output "int main() {}" > .\test.cu
    # Windows PowerShell treats redirected native stderr as an error when this is Stop.
    $previous_error_action_preference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $LASTEXITCODE = $null
        $nvcc_output = @(nvcc -v .\test.cu -D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH 2>&1)
        $nvcc_exit_code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous_error_action_preference
    }

    $nvcc_output_text = @($nvcc_output | ForEach-Object { $_.ToString() })
    $nvcc_output_text | Write-Output
    if ($nvcc_exit_code -ne 0 -and
        -not (($nvcc_output_text -join "`n").Contains("The nvcc flag '-allow-unsupported-compiler' can be used to override this version check;"))) {
        throw 'Step Failed'
    }
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
