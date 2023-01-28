#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

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

echo "Downloading LLVM gpg key...";

tmpdir="$(mktemp -d)";
wget --no-hsts -q -O $tmpdir/llvm-snapshot.asc https://apt.llvm.org/llvm-snapshot.gpg.key;

find "$tmpdir" -type f -name '*.asc' -exec bash -c "gpg --dearmor -o \
  /etc/apt/trusted.gpg.d/\$(echo '{}' | sed s@$tmpdir/@@ | sed s@.asc@.gpg@) \
  {}" \;

chmod 0644 /etc/apt/trusted.gpg.d/*.gpg || true;

LLVM_VERSION="${VERSION:-}";

echo "Installing LLVM compilers and tools${LLVM_VERSION:+" (version=${LLVM_VERSION})"}";

# If LLVM_VERSION is "latest", install OS distribution
if [[ "${LLVM_VERSION}" == "latest" ]]; then
    LLVM_VERSION="";
    apt_get_update;
else

    if [[ "$LLVM_VERSION" == "dev" || "$LLVM_VERSION" == "pre" || "$LLVM_VERSION" == "prerelease" ]]; then
        LLVM_VERSION="";
    fi

    # Install llvm apt repository
    apt-add-repository -n -y "\
deb http://apt.llvm.org/$(lsb_release -cs)/ \
llvm-toolchain-$(lsb_release -cs)${LLVM_VERSION:+"-$LLVM_VERSION"} main";

    # If adding the versioned repo failed, add the dev apt repo. This should
    # only happen if installing the dev version by version number before it's
    # released (e.g. 16 while llvm-15 is the current mainline)
    if ! apt-get update -y > /dev/null 2>&1; then

        rm /etc/apt/sources.list.d/*llvm*.list;

        apt-add-repository -y "\
deb http://apt.llvm.org/$(lsb_release -cs)/ \
llvm-toolchain-$(lsb_release -cs) main";

        LLVM_VERSION="";
    fi
fi

if [[ -z "$LLVM_VERSION" ]]; then
    LLVM_VERSION="$(\
        apt-cache search '^llvm-[0-9]+$' \
      | cut -d' ' -f1 | cut -d'-' -f2 \
      | sort -rn | head -n1
    )";
fi

DEBIAN_FRONTEND=noninteractive                                           \
apt-get install -y --no-install-recommends                               \
    `# -o Dpkg::Options::="--force-overwrite"`                           \
    `# LLVM and Clang`                                                   \
    llvm-${LLVM_VERSION}-runtime                                         \
    {clang-tools,python3-clang,python3-lldb}-${LLVM_VERSION}             \
    {libc++,libc++abi,libclang,liblldb,libomp,llvm}-${LLVM_VERSION}-dev  \
    {clang-format,clang-tidy,clang,clangd,lld,lldb,llvm}-${LLVM_VERSION} \
    ;

# Remove existing clang/llvm/cc/c++ alternatives
(update-alternatives --remove-all clang        >/dev/null 2>&1 || true);
(update-alternatives --remove-all clangd       >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang++      >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang-format >/dev/null 2>&1 || true);
(update-alternatives --remove-all clang-tidy   >/dev/null 2>&1 || true);
(update-alternatives --remove-all lldb         >/dev/null 2>&1 || true);
(update-alternatives --remove-all llvm-config  >/dev/null 2>&1 || true);
(update-alternatives --remove-all llvm-cov     >/dev/null 2>&1 || true);
(update-alternatives --remove-all cc           >/dev/null 2>&1 || true);
(update-alternatives --remove-all c++          >/dev/null 2>&1 || true);

# Install clang/llvm alternatives
update-alternatives \
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

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
