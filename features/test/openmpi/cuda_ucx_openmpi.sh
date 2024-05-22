#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features ucx \
#     --base-image ubuntu:22.04 .'
# ```

set -ex

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

>&2 echo "PATH=$PATH"
>&2 echo "BASH_ENV=$BASH_ENV"

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "ucx_info exists and is on path" which ucx_info

echo "UCX_VERSION: $UCX_VERSION";
ucx_info -v;

check "ucx version" bash -c "grep '$UCX_VERSION' <(ucx_info -v | head -n1 | cut -d' ' -f4)";

echo "OPENMPI_VERSION: $OPENMPI_VERSION";

check "mpicc exists and is on path" which mpicc
mpicc --version
check "mpicc --version works" mpicc --version

check "mpicxx exists and is on path" which mpicxx
mpicxx --version
check "mpicxx --version works" mpicxx --version

check "mpirun exists and is on path" which mpirun
mpirun --version
check "mpirun --version works" mpirun --version
check "mpirun version" bash -c "grep '$OPENMPI_VERSION' <(mpirun --version | head -n1 | cut -d' ' -f4)";

check "OMPI_MCA_btl is ucx" test "${OMPI_MCA_btl:-}" = ucx
check "OMPI_MCA_pml is ucx" test "${OMPI_MCA_pml:-}" = ucx
check "OMPI_MCA_osc is ucx" test "${OMPI_MCA_osc:-}" = ucx

check "OMPI_MCA_opal_cuda_support is true" test "${OMPI_MCA_opal_cuda_support:-}" = true

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
