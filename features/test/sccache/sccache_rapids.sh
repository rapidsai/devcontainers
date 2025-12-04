#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cuda \
#     --base-image ubuntu:22.04 .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "sccache exists and is on path" which sccache
echo "sccache version: $(sccache --version)"

check "installed latest RAPIDS sccache" bash -c 'sccache --version | grep -q "rapids"'

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
