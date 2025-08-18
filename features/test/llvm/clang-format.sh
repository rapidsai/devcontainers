#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features llvm \
#     --base-image ubuntu:22.04 .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.

echo "LLVM_VERSION: $LLVM_VERSION";
check "version" bash -c "echo '$LLVM_VERSION' | grep '17'";
check "clang-format version" bash -c "clang-format --version | grep 'clang-format version $LLVM_VERSION'";
check "apt repo" grep "llvm-toolchain-$(lsb_release -cs)-17 main" $(find /etc/apt -type f -name '*.list');

check "clang is not installed" bash -c '! command -V clang';
check "clang++ is not installed" bash -c '! command -V clang++';
check "clang-format is installed" bash -c 'which clang-format';

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
