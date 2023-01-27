#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features nvhpc \
#     --base-image mcr.microsoft.com/devcontainers/base:jammy .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

>&2 echo "NVHPC=$NVHPC"
>&2 echo "NVHPC_ROOT=$NVHPC_ROOT"
>&2 echo "NVHPC_VERSION=$NVHPC_VERSION"
>&2 echo "NVHPC_CUDA_HOME=$NVHPC_CUDA_HOME"
ls -all "$NVHPC_ROOT"/ 1>&2

>&2 echo "BASH_ENV=$BASH_ENV"
>&2 echo "PATH=$PATH"
module list 1>&2

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "version" bash -c "echo '$NVHPC_VERSION' | grep '22.11'"
check "installed" stat /opt/nvidia/hpc_sdk
check "nvc++ exists and is on path" which nvc++

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
