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
    while ! wget --no-hsts -q -O /tmp/cmake_${CMAKE_VERSION}.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -p).sh; do
        echo "(!) cmake version ${CMAKE_VERSION} failed to download. Attempting to fall back one version to retry...";
        find_prev_version_from_git_tags CMAKE_VERSION https://github.com/Kitware/CMake;
    done
else
    wget --no-hsts -q -O /tmp/cmake_${CMAKE_VERSION}.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -p).sh;
fi

echo "Installing CMake...";

# Install CMake
bash /tmp/cmake_${CMAKE_VERSION}.sh --skip-license --exclude-subdir --prefix=/usr;


rm -rf /tmp/cmake_${CMAKE_VERSION}.sh;
