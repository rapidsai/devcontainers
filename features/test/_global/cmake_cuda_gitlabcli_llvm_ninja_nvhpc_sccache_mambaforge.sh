#! /usr/bin/env bash

# The 'test/_global' folder is a special test folder that is not tied to a single feature.
#
# This test file is executed against a running container constructed
# from the value of 'color_and_hello' in the tests/_global/scenarios.json file.
#
# The value of a scenarios element is any properties available in the 'devcontainer.json'.
# Scenarios are useful for testing specific options in a feature, or to test a combination of features.
#
# This test can be run with the following command (from the root of this repo)
#    devcontainer features test --global-scenarios-only .

set -e;

# Check bash env
(
    echo "----------------------------";
    set -x;
    env;
    echo "" 2>/dev/null;
    cat /etc/environment;
    echo "" 2>/dev/null;
    for x in /etc/profile.d/*.sh; do
        cat "$x";
        echo "" 2>/dev/null;
    done;
    echo "" 2>/dev/null;
    cat ~/.bashrc;
    echo "" 2>/dev/null;
    { set +x; } 2>/dev/null;
    echo "----------------------------";
)

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib;

# Check GitLab CLI
check "gitlab-cli version" glab --version

# Check CUDA
check "CUDA version" bash -c "echo '$CUDA_VERSION' | grep '12.0.0'";
check "CUDA major version" bash -c "echo '$CUDA_VERSION_MAJOR' | grep '12'";
check "CUDA minor version" bash -c "echo '$CUDA_VERSION_MINOR' | grep '0'";
check "CUDA patch version" bash -c "echo '$CUDA_VERSION_PATCH' | grep '0'";
check "installed" stat /usr/local/cuda-12.0 /usr/local/cuda;
check "nvcc exists and is on path" which nvcc;

# Check NVHPC
>&2 echo "NVHPC=$NVHPC";
>&2 echo "NVHPC_ROOT=$NVHPC_ROOT";
>&2 echo "NVHPC_VERSION=$NVHPC_VERSION";
>&2 echo "NVHPC_CUDA_HOME=$NVHPC_CUDA_HOME";
ls -all "$NVHPC_ROOT"/ 1>&2;

module list 1>&2;

check "version" bash -c "echo '$NVHPC_VERSION' | grep '23.01'";
check "installed" stat /opt/nvidia/hpc_sdk;
check "nvc++ exists and is on path" which nvc++;

# Check LLVM
echo "LLVM_VERSION: $LLVM_VERSION";
check "clang version" bash -c "clang --version | grep 'clang version 16'";
check "apt repo" grep "llvm-toolchain-$(lsb_release -cs)-16 main" /etc/apt/sources.list{,.d/*.list};

# Check CMake
CMAKE_VERSION="3.25.2";
check "cmake exists and is on path" which cmake;
check "version" bash -c "cmake --version | grep '$CMAKE_VERSION'";

# Check ninja
NINJA_VERSION="1.11.1";
check "ninja exists and is on path" which ninja;
check "version" bash -c "ninja --version | grep '$NINJA_VERSION'";

# Check sccache
SCCACHE_VERSION="0.3.1";
check "sccache exists and is on path" which sccache;
check "version" bash -c "sccache --version | grep '$SCCACHE_VERSION'";

# Check Mambaforge
check "conda exists and is on path" which conda;
check "mamba exists and is on path" which mamba;
check "mamba no banner" bash -c "echo '$MAMBA_NO_BANNER' | grep '1'";

conda --version;
mamba --version;

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults;
