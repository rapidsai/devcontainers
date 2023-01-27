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

# Check bash env
>&2 echo "PATH=$PATH";
>&2 echo "BASH_ENV=$BASH_ENV";

# Check CUDA
check "CUDA version" bash -c "echo '$CUDA_VERSION' | grep '12.0.0'";
check "CUDA major version" bash -c "echo '$CUDA_VERSION_MAJOR' | grep '12'";
check "CUDA minor version" bash -c "echo '$CUDA_VERSION_MINOR' | grep '0'";
check "CUDA patch version" bash -c "echo '$CUDA_VERSION_PATCH' | grep '0'";
check "installed" stat /usr/local/cuda-12.0 /usr/local/cuda;
check "nvcc exists and is on path" which nvcc;

# Check Rust
check "cargo version" cargo  --version
check "rustc version" rustc  --version

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults;
