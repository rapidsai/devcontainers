#! /usr/bin/env bash
set -e

NINJA_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq wget unzip ca-certificates bash-completion;

echo "Installing ninja-build...";

if [ "${NINJA_VERSION}" = latest ]; then
    find_version_from_git_tags NINJA_VERSION https://github.com/ninja-build/ninja;
fi

_name="ninja-linux";

if test "$(uname -p)" = "aarch64"; then
    _name+="-aarch64";
fi

# Install Ninja
wget --no-hsts -q -O /tmp/ninja-linux.zip \
    "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/${_name}.zip";
unzip -d /usr/bin /tmp/ninja-linux.zip;
chmod +x /usr/bin/ninja;

# Install Ninja bash completions
wget --no-hsts -q -O /usr/share/bash-completion/completions/ninja \
    "https://github.com/ninja-build/ninja/raw/v${NINJA_VERSION}/misc/bash-completion";

# Clean up
rm -rf /var/tmp/*;

rm -rf /tmp/ninja-linux.zip;
