#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cccl-dev \
#     --base-image ubuntu:22.04 .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "lit exists and is on path" which lit
echo "lit version: $(lit --version)"
check "TBB_ROOT is defined" test -n "$TBB_ROOT"
echo "TBB_ROOT: $TBB_ROOT"
check "TBB_ROOT is a directory" test -d "$TBB_ROOT"
check "\$TBB_ROOT/lib/cmake/tbb/TBBConfig.cmake exists" test -f "$TBB_ROOT/lib/cmake/tbb/TBBConfig.cmake"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
