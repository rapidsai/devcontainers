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

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "on-create-command.sh exists" stat /opt/devcontainer/bin/on-create-command.sh
check "update-content-command.sh exists" stat /opt/devcontainer/bin/update-content-command.sh
check "post-create-command.sh exists" stat /opt/devcontainer/bin/post-create-command.sh
check "post-start-command.sh exists" stat /opt/devcontainer/bin/post-start-command.sh
check "post-attach-command.sh exists" stat /opt/devcontainer/bin/post-attach-command.sh

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
