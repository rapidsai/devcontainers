#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

UPDATE_RC="${UPDATERC:-"true"}";
UPDATE_RUST="${UPDATERUST:-"false"}";
RUST_VERSION="${VERSION:-"latest"}";
RUSTUP_PROFILE="${PROFILE:-"minimal"}";

set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_nightly_version_formatting() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi

    local version_date=$(echo ${requested_version} | sed -e "s/^nightly-//")

    date -d ${version_date} &>/dev/null
    if [ $? != 0 ]; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nNightly version should be in the format nightly-YYYY-MM-DD" >&2
        exit 1
    fi

    if [ $(date -d ${version_date} +%s) -ge $(date +%s) ]; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nNightly version should not exceed current date" >&2
        exit 1
    fi
}

export DEBIAN_FRONTEND=noninteractive;

gcc_pkgs="gcc g++";

if [[ -n "${GCC_VERSION:-}" ]]; then
    gcc_pkgs="gcc-${GCC_VERSION} g++-${GCC_VERSION}";
fi

lldb_pkg="lldb";

if [[ -n "${LLVM_VERSION:-}" ]]; then
    lldb_pkg="lldb-${LLVM_VERSION}";
elif type llvm-config &> /dev/null; then
    lldb_pkg="lldb-$(llvm-config --version | cut -d':' -f3 | cut -d'.' -f1)";
fi

# Install curl, lldb, python3-minimal,libpython and rust dependencies if missing
check_packages curl ca-certificates ${gcc_pkgs} libc6-dev libssl-dev gnupg2 gettext-base;

if ! dpkg -s gnupg2 ${lldb_pkg} python3-minimal > /dev/null 2>&1; then
    apt-get -y install ${lldb_pkg} python3-minimal libpython3.?;
fi

architecture="${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";
download_architecture="${architecture}";

case ${download_architecture} in
 amd64)
    download_architecture="x86_64"
    ;;
 arm64)
    download_architecture="aarch64"
    ;;
 *) echo "(!) Architecture ${architecture} not supported."
    exit 1
    ;;
esac

# Install Rust
umask 0002
if ! cat /etc/group | grep -e "^rustlang:" > /dev/null 2>&1; then
    groupadd -r rustlang;
fi

# Determine the appropriate non-root user
find_non_root_user;
usermod -a -G rustlang "${USERNAME}";
mkdir -p "${CARGO_HOME}" "${RUSTUP_HOME}";
chown "${USERNAME}:rustlang" "${RUSTUP_HOME}" "${CARGO_HOME}";
chmod g+r+w+s "${RUSTUP_HOME}" "${CARGO_HOME}";

if [ "${RUST_VERSION}" = "none" ] || type rustup > /dev/null 2>&1; then
    echo "Rust already installed. Skipping...";
else
    if [ "${RUST_VERSION}" != "latest" ] && [ "${RUST_VERSION}" != "lts" ] && [ "${RUST_VERSION}" != "stable" ]; then
        # Find version using soft match
        if ! type git > /dev/null 2>&1; then
            check_packages git;
        fi

        is_nightly=0;
        echo ${RUST_VERSION} | grep -q "nightly" || is_nightly=$?;
        if [ $is_nightly = 0 ]; then
            check_nightly_version_formatting RUST_VERSION;
        else
            find_version_from_git_tags RUST_VERSION "https://github.com/rust-lang/rust" "tags/";
        fi
        default_toolchain_arg="--default-toolchain ${RUST_VERSION}";
    fi
    echo "Installing Rust...";
    # Download and verify rustup sha
    mkdir -p /tmp/rustup/target/${download_architecture}-unknown-linux-gnu/release/;
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init" -o /tmp/rustup/target/${download_architecture}-unknown-linux-gnu/release/rustup-init;
    curl -sSL --proto '=https' --tlsv1.2 "https://static.rust-lang.org/rustup/dist/${download_architecture}-unknown-linux-gnu/rustup-init.sha256" -o /tmp/rustup/rustup-init.sha256;
    cd /tmp/rustup;
    sha256sum -c rustup-init.sha256;
    chmod +x target/${download_architecture}-unknown-linux-gnu/release/rustup-init;
    target/${download_architecture}-unknown-linux-gnu/release/rustup-init -y --no-modify-path --profile ${RUSTUP_PROFILE} ${default_toolchain_arg};
    cd -;
    rm -rf /tmp/rustup;
fi

export PATH="${CARGO_HOME}/bin:${PATH}";

if [ "${UPDATE_RUST}" = "true" ]; then
    echo "Updating Rust...";
    rustup update 2>&1;
fi

echo "Installing common Rust dependencies...";

rustup component add rls rust-analysis rust-src rustfmt clippy 2>&1;

# Add CARGO_HOME, RUSTUP_HOME and bin directory into bashrc/zshrc files (unless disabled)
if [ "${UPDATE_RC}" = "true" ]; then
    append_etc_zshrc "$(cat .bashrc | envsubst)";
    append_to_etc_bashrc "$(cat .bashrc | envsubst)";
    append_to_all_bashrcs "$(cat .bashrc | envsubst)";
fi

# Make files writable for rustlang group
chmod -R g+r+w "${RUSTUP_HOME}" "${CARGO_HOME}";

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
