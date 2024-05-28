#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cuda \
#     --base-image ubuntu:22.04 .'
# ```

set -ex

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

>&2 echo "PATH=$PATH"
>&2 echo "BASH_ENV=$BASH_ENV"

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
echo "OPENMPI_VERSION: $OPENMPI_VERSION";

check "mpicc exists and is on path" which mpicc
mpicc --version

check "mpicxx exists and is on path" which mpicxx
mpicxx --version

check "mpirun exists and is on path" which mpirun
mpirun --version

check "mpirun version" bash -c "grep '$OPENMPI_VERSION' <(mpirun --version | head -n1 | cut -d' ' -f4)";

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
