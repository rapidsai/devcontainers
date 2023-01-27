#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cuda \
#     --base-image mcr.microsoft.com/devcontainers/base:jammy .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

>&2 echo "PATH=$PATH"
>&2 echo "BASH_ENV=$BASH_ENV"

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "CUDA version" bash -c "echo '$CUDA_VERSION' | grep '12.0.0'";
check "CUDA major version" bash -c "echo '$CUDA_VERSION_MAJOR' | grep '12'";
check "CUDA minor version" bash -c "echo '$CUDA_VERSION_MINOR' | grep '0'";
check "CUDA patch version" bash -c "echo '$CUDA_VERSION_PATCH' | grep '0'";
check "installed" stat /usr/local/cuda-12.0 /usr/local/cuda
check "nvcc exists and is on path" which nvcc

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
