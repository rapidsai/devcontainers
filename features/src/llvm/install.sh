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

declare -a bins=();
declare -a pkgs=();
IFS=" " read -r -a pkgs <<< "${PACKAGES:-all}";

./llvm.sh "${LLVM_VERSION}" "${pkgs[@]}";

if [[ "${pkgs[*]}" == "all" ]]; then
    bins=("clang" "clangd" "clang++" "clang-format" "clang-tidy" "lldb" "llvm-config" "llvm-cov" "FileCheck" "UnicodeNameMappingGenerator");
else
    IFS=" " read -r -a bins <<< "${PACKAGES}";
    declare -A pkgs_map=();
    for ((i=0; i < ${#pkgs[@]}; i+=1)); do
        pkgs_map["${pkgs[i]}"]=1;
    done
    if test -v pkgs_map["llvm-tools"] \
    || test -v pkgs_map["llvm-${LLVM_VERSION}-tools"]; then
        bins+=("FileCheck" "UnicodeNameMappingGenerator");
    fi
fi

# Remove existing, install, and set default clang/llvm alternatives
for ((i=0; i < ${#bins[@]}; i+=1)); do
    x=${bins[$i]};
    if type "${x}-${LLVM_VERSION}" >/dev/null 2>&1; then
        (update-alternatives --install /usr/bin/"${x}" "${x}" "$(which "${x}-${LLVM_VERSION}")" 30);
        (update-alternatives --set "${x}" "$(which "${x}-${LLVM_VERSION}")");
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
