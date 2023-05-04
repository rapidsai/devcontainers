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

check "icc exists and is on path" which icc
echo "icc version: $(icc --version)"

check "icpc exists and is on path" which icpc
echo "icpc version: $(icpc --version)"

check "icx exists and is on path" which icx
echo "icx version: $(icx --version)"

check "icpx exists and is on path" which icpx
echo "icpx version: $(icpx --version)"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
