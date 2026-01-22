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
check "ucx_info exists and is on path" which ucx_info

echo "UCX_VERSION: $UCX_VERSION";
ucx_info -v;

check "ucx version" bash -c "echo '$UCX_VERSION' | grep '$(ucx_info -v | head -n1 | cut -d' ' -f4)'";

check "libnvidia-compute is not installed" bash -c "! dpkg -s libnvidia-compute";

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
