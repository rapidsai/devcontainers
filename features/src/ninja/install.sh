#! /usr/bin/env bash
set -e

NINJA_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

PKG=();
PKG+=("jq");
PKG+=("git");
PKG+=("make");
PKG+=("wget");
PKG+=("file");
PKG+=("unzip");
PKG+=("ca-certificates");
PKG+=("bash-completion");
PKG_TO_REMOVE=();

if ! type gcc >/dev/null 2>&1; then
    PKG+=("gcc");
    PKG_TO_REMOVE+=("gcc");
fi
if ! type g++ >/dev/null 2>&1; then
    PKG+=("g++");
    PKG_TO_REMOVE+=("g++");
fi

check_packages ${PKG[@]};

if ! type cmake >/dev/null 2>&1; then
    CMAKE_VERSION=latest;
    find_version_from_git_tags CMAKE_VERSION https://github.com/Kitware/CMake;

    wget --no-hsts -q -O /tmp/cmake_${CMAKE_VERSION}.sh \
        https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -p).sh;

    echo "Installing CMake...";

    # Install CMake
    mkdir -p /tmp/cmake
    bash /tmp/cmake_${CMAKE_VERSION}.sh --skip-license --exclude-subdir --prefix=/tmp/cmake;
    cmake="/tmp/cmake/bin/cmake";
else
    cmake="$(which cmake)";
fi

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
    /tmp/ninja;

# Configure Ninja
$cmake -S /tmp/ninja -B /tmp/ninja/build -DCMAKE_BUILD_TYPE=Release;
# Build Ninja
$cmake --build /tmp/ninja/build --parallel --config Release;
# Install Ninja
strip /tmp/ninja/build/ninja;
file /tmp/ninja/build/ninja;
$cmake --install /tmp/ninja/build;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
rm -rf /tmp/{cmake,ninja};
rm -rf /tmp/cmake_${CMAKE_VERSION}.sh;

if [[ ${#PKG_TO_REMOVE[@]} -gt 0 ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y remove ${PKG_TO_REMOVE[@]};
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
fi
