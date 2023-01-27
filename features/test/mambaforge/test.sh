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

MAMBAFORGE_VERSION="$(wget -O- -q https://api.github.com/repos/conda-forge/miniforge/releases/latest | jq -r ".tag_name" | tr -d 'v')";

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "conda exists and is on path" which conda
check "mamba exists and is on path" which mamba
check "mamba no banner" bash -c "echo '$MAMBA_NO_BANNER' | grep '1'"

conda --version
mamba --version

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
