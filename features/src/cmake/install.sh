#! /usr/bin/env bash
set -e

CMAKE_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq wget ca-certificates bash-completion pkg-config;

echo "Downloading CMake...";

if [[ "${CMAKE_VERSION}" == "latest" ]]; then
    find_version_from_git_tags CMAKE_VERSION https://github.com/Kitware/CMake;
fi

wget --no-hsts -q -O /tmp/cmake_${CMAKE_VERSION}.sh \
    https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -p).sh;

echo "Installing CMake...";

# Install CMake
bash /tmp/cmake_${CMAKE_VERSION}.sh --skip-license --exclude-subdir --prefix=/usr;

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
rm -rf "/tmp/cmake_${CMAKE_VERSION}.sh";
