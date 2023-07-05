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

    Write-Output "int main() {return 0;}" > .\test.cpp
    cl .\test.cpp
    TestReturnCode

    Write-Output "Test CMake"
    cmake --version
    TestReturnCode

    Write-Output "Test NVCC"
    nvcc --version
    TestReturnCode

    Write-Output "int main() {return 0;}" > .\test.cu
    nvcc .\test.cu
    TestReturnCode
}
catch {
    Pop-Location
    throw
}
finally {
    Pop-Location
}
