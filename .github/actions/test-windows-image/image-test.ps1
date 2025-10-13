function TestReturnCode {
    if (-not $?) {
        throw 'Step Failed'
    }
}

$mismatch_nvcc_cl_flags = @(
    # Tell NVCC that old msvc is okay
    '--allow-unsupported-compiler',
    # Tell MSVC that new nvcc is okay
    '-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH'
)

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

    Write-Output "int main() {return 0;}" > .\test.cpp
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
    nvcc --version @mismatch_nvcc_cl_flags
    TestReturnCode

    Write-Output "int main() {return 0;}" > .\test.cu
    nvcc -v .\test.cu @mismatch_nvcc_cl_flags
    TestReturnCode
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
