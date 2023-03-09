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

>&2 echo "PATH=$PATH"
>&2 echo "BASH_ENV=$BASH_ENV"

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "GCC version" bash -c "echo '$GCC_VERSION' | grep '12'";
check "GCC version" bash -c "echo '$(gcc -dumpversion)' | grep '12'";
check "gcc exists and is on path" which gcc
check "g++ exists and is on path" which g++

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
