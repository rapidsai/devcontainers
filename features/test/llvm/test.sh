#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features llvm \
#     --base-image mcr.microsoft.com/devcontainers/base:jammy .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.

echo "LLVM_VERSION: $LLVM_VERSION"
check "clang version" bash -c "clang --version | grep 'clang version $LLVM_VERSION'"
check "apt repo" grep "llvm-toolchain-$(lsb_release -cs) main" /etc/apt/sources.list{,.d/*.list}

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
