#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

LLVM_VERSION="${VERSION:-}";

check_packages                  \
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

echo "Installing llmv-${LLVM_VERSION} compilers and tools";

./llvm.sh $LLVM_VERSION all;

# # Remove existing cc/c++ alternatives
# (update-alternatives --remove-all cc           >/dev/null 2>&1 || true);
# (update-alternatives --remove-all c++          >/dev/null 2>&1 || true);

# # Install cc/c++ alternatives
# update-alternatives                                                                    \
#     --install /usr/bin/cc           cc           $(which clang-${LLVM_VERSION}) 30     \
#     --slave   /usr/bin/c++          c++          $(which clang++-${LLVM_VERSION})      \
#     ;

# # Set default cc/c++ alternatives
# update-alternatives --set cc $(which clang-${LLVM_VERSION});

# Remove existing clang/llvm alternatives
(update-alternatives --remove-all clang        >/dev/null 2>&1 || true);
(update-alternatives --remove-all clangd       >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang++      >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang-format >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang-tidy   >/dev/null 2>&1 || true);
(update-alternatives --remove-all lldb         >/dev/null 2>&1 || true);
(update-alternatives --remove-all llvm-config  >/dev/null 2>&1 || true);
(update-alternatives --remove-all llvm-cov     >/dev/null 2>&1 || true);

# Install clang/llvm alternatives
update-alternatives                                                                    \
    --install /usr/bin/clang        clang        $(which clang-${LLVM_VERSION}) 30     \
    --slave   /usr/bin/clangd       clangd       $(which clangd-${LLVM_VERSION})       \
    --slave   /usr/bin/clang++      clang++      $(which clang++-${LLVM_VERSION})      \
    --slave   /usr/bin/clang-format clang-format $(which clang-format-${LLVM_VERSION}) \
    --slave   /usr/bin/clang-tidy   clang-tidy   $(which clang-tidy-${LLVM_VERSION})   \
    --slave   /usr/bin/lldb         lldb         $(which lldb-${LLVM_VERSION})         \
    --slave   /usr/bin/llvm-config  llvm-config  $(which llvm-config-${LLVM_VERSION})  \
    --slave   /usr/bin/llvm-cov     llvm-cov     $(which llvm-cov-${LLVM_VERSION})     \
    ;

# Set default clang/llvm alternatives
update-alternatives --set clang $(which clang-${LLVM_VERSION});

export LLVM_VERSION="${LLVM_VERSION}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";
# export envvars in /etc/profile.d
add_etc_profile_d_script llvm "$(cat .bashrc | envsubst)";

# Copy clangd config into etc/skel
mkdir -p -m 0755 /etc/skel/.config/clangd/;
cp .clangd /etc/skel/.config/clangd/config.yaml;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
