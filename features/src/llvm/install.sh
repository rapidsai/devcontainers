#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

LLVM_VERSION="${VERSION:-}";

check_packages                  \
    git                         \
    gpg                         \
    wget                        \
    apt-utils                   \
    lsb-release                 \
    gettext-base                \
    bash-completion             \
    ca-certificates             \
    apt-transport-https         \
    software-properties-common  \
    ;

install_clang_grace() {
    if [[ "$(uname -p)" != "aarch64" ]]; then
        echo "Clang for Grace is only supported on aarch64"
        exit 0;
    fi

    echo "Installing NVIDIA Clang for Grace"
    wget -O clang-grace-toolchain.deb https://developer.nvidia.com/downloads/assets/grace/clang/16.23.08/clang-grace-toolchain_16.23.08_arm64.deb
    apt-get -y install ./clang-grace-toolchain.deb

    PATH="/opt/nvidia/clang/16.23.08/bin:$PATH"
    (update-alternatives --install /usr/bin/clang clang $(which clang) 30);
    (update-alternatives --install /usr/bin/clang-16 clang-16 $(which clang) 30);
    (update-alternatives --install /usr/bin/clang++ clang $(which clang++) 30);
    (update-alternatives --install /usr/bin/clang++-16 clang++-16 $(which clang++) 30);
}

install_llvm() {
    if [[ -z "$LLVM_VERSION" \
        || "$LLVM_VERSION" == "latest" \
        || "$LLVM_VERSION" == "dev" \
        || "$LLVM_VERSION" == "pre" \
        || "$LLVM_VERSION" == "prerelease" \
    ]]; then
        LLVM_VERSION="latest";
        find_version_from_git_tags \
            LLVM_VERSION \
            https://github.com/llvm/llvm-project \
            "tags/llvmorg-" "." "-init" "true";
        LLVM_VERSION="$(echo $LLVM_VERSION | grep -oP '[0-9]+')";
    fi

    echo "Installing llvm-${LLVM_VERSION} compilers and tools";

    ./llvm.sh $LLVM_VERSION ${PACKAGES:-all};
}

if [[ "$LLVM_VERSION" == "16.grco" ]]; then
    LLVM_VERSION="16"
    install_llvm
    install_clang_grace
    LLVM_TOOLS=( clangd clang-format clang-tidy )
else
    install_llvm
    LLVM_TOOLS=( clang clangd clang++ clang-format clang-tidy lldb llvm-config llvm-cov )
fi

# Remove existing, install, and set default clang/llvm alternatives
for x in ${LLVM_TOOLS[@]}; do
    if type ${x}-${LLVM_VERSION} >/dev/null 2>&1; then
        if ${x} != clang-format; then
            (update-alternatives --remove-all ${x} >/dev/null 2>&1 || true);
        fi
        (update-alternatives --install /usr/bin/${x} ${x} $(which ${x}-${LLVM_VERSION}) 30);
        (update-alternatives --set ${x} $(which ${x}-${LLVM_VERSION}));
    fi
done

export LLVM_VERSION="${LLVM_VERSION}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";
# export envvars in /etc/profile.d
add_etc_profile_d_script llvm "$(cat .bashrc | envsubst)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
