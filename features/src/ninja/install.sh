#! /usr/bin/env bash
set -ex

NINJA_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq git gcc g++ make wget file unzip ca-certificates bash-completion;

echo "Installing ninja-build...";

if [ $NINJA_VERSION == latest ]; then
    find_version_from_git_tags NINJA_VERSION https://github.com/ninja-build/ninja;
fi

# Clone Ninja
git clone \
    -j$(nproc) \
    --single-branch \
    --shallow-submodules \
    --recurse-submodules \
    --branch "v$NINJA_VERSION" \
    https://github.com/ninja-build/ninja \
    /tmp/ninja

# Configure Ninja
cmake -S /tmp/ninja -B /tmp/ninja/build -DCMAKE_BUILD_TYPE=Release;
# Build Ninja
cmake --build /tmp/ninja/build --parallel --config Release;
# Install Ninja
strip /tmp/ninja/build/ninja;
file /tmp/ninja/build/ninja;
cmake --install /tmp/ninja/build;

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
