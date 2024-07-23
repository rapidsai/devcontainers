#!/bin/bash
################################################################################
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
################################################################################
#
# This script will install the llvm toolchain on the different
# Debian and Ubuntu versions

set -eux

usage() {
    local -;
    set +x
    echo "Usage: $0 [llvm_major_version] [all] [OPTIONS]" 1>&2
    echo -e "all\t\t\tInstall all packages." 1>&2
    echo -e "-n=code_name\t\tSpecifies the distro codename, for example bionic" 1>&2
    echo -e "-h\t\t\tPrints this help." 1>&2
    echo -e "-m=repo_base_url\tSpecifies the base URL from which to download." 1>&2
    exit 1;
}

BASE_URL="http://apt.llvm.org"

# Check for required tools
needed_binaries=(lsb_release wget add-apt-repository gpg git)
missing_binaries=()
for binary in "${needed_binaries[@]}"; do
    if ! which $binary >/dev/null 2>&1 ; then
        missing_binaries+=($binary)
    fi
done
if [[ ${#missing_binaries[@]} -gt 0 ]] ; then
    echo "You are missing some tools this script requires: ${missing_binaries[@]}"
    echo "(hint: apt install lsb-release wget software-properties-common gnupg)"
    exit 4
fi

# Set default values for commandline arguments
DISTRO=$(lsb_release -is)
VERSION=$(lsb_release -sr)
UBUNTU_CODENAME=""
CODENAME_FROM_ARGUMENTS=""
# Obtain VERSION_CODENAME and UBUNTU_CODENAME (for Ubuntu and its derivatives)
source /etc/os-release
DISTRO=${DISTRO,,}
case ${DISTRO} in
    debian)
        if [[ "${VERSION}" == "unstable" ]] || [[ "${VERSION}" == "testing" ]] || [[ "${VERSION_CODENAME}" == "bookworm" ]]; then
            # For now, bookworm == sid.
            # TODO change when bookworm is released
            CODENAME=unstable
            LINKNAME=
        else
            # "stable" Debian release
            CODENAME=${VERSION_CODENAME}
            LINKNAME=-${CODENAME}
        fi
        ;;
    *)
        # ubuntu and its derivatives
        if [[ -n "${UBUNTU_CODENAME}" ]]; then
            CODENAME=${UBUNTU_CODENAME}
            if [[ -n "${CODENAME}" ]]; then
                LINKNAME=-${CODENAME}
            fi
        fi
        ;;
esac

# read command line arguments
LLVM_VERSION=$1;
PKG=(${*:2});

while getopts ":hm:n:" arg; do
    case $arg in
    h)
        usage
        ;;
    m)
        BASE_URL=${OPTARG}
        ;;
    n)
        CODENAME=${OPTARG}
        if [[ "${CODENAME}" == "unstable" ]]; then
            # link name does not apply to unstable repository
            LINKNAME=
        else
            LINKNAME=-${CODENAME}
        fi
        CODENAME_FROM_ARGUMENTS="true"
        ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

echo "pkgs: ${PKG[@]}";

llvm_versions=($(git ls-remote --tags    \
    https://github.com/llvm/llvm-project \
    refs/tags/llvmorg-*-init             \
  | cut -f2                              \
  | sed 's@refs/tags/llvmorg-@@'         \
  | sed -r 's@([0-9]+)[\.-].*?@\1@'      \
  | sort -urV                            \
));

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9";

for ((i=0; i < ${#llvm_versions[@]}; i+=1)); do
    LLVM_VERSION_PATTERNS[${llvm_versions[$i]}]="-${llvm_versions[$i]}";
done

LLVM_VERSION_PATTERNS[${llvm_versions[0]}]="";

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
    echo "This script does not support LLVM version $LLVM_VERSION"
    exit 3
fi

LLVM_VERSION_STRING="${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}"

# join the repository name
if [[ -n "${CODENAME}" ]]; then

    retry_count=0;

    while ! wget --no-hsts -q --method=HEAD \
            "${BASE_URL}/${CODENAME}/dists/llvm-toolchain${LINKNAME}${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}/Release" >/dev/null 2>&1; do
        if test $(( retry_count++ )) -ge 5; then
            LLVM_VERSION_STRING=
            break;
        fi
        sleep_time=$((retry_count * 5))
        echo "Attempt $retry_count failed! Trying again in $sleep_time seconds..."
        sleep $sleep_time
    done

    REPO_NAME="deb ${BASE_URL}/${CODENAME}/  llvm-toolchain${LINKNAME}${LLVM_VERSION_STRING} main"

    # check if the repository exists for the distro and version
    if ! wget --no-hsts -q --method=HEAD "${BASE_URL}/${CODENAME}" >/dev/null 2>&1; then
        if [[ -n "${CODENAME_FROM_ARGUMENTS}" ]]; then
            echo "Specified codename '${CODENAME}' is not supported by this script."
        else
            echo "Distribution '${DISTRO}' in version '${VERSION}' is not supported by this script."
        fi
        exit 2
    fi
fi


# install everything

if [ ! -f /etc/apt/trusted.gpg.d/apt.llvm.org.asc ]; then
    # download GPG key once
    wget --no-hsts -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
fi

if [[ -z "`apt-key list 2> /dev/null | grep -i llvm`" ]]; then
    # Delete the key in the old format
    apt-key del AF4F7421
fi

cat <<"EOF" >> "/etc/apt/preferences.d/llvm-$LLVM_VERSION"
Package: *
Pin: origin *llvm.org*
Pin-Priority: 600
EOF

add-apt-repository -n -y "${REPO_NAME}"

if [[ "${PKG[*]}" == "" ]]; then
    PKG=();
    PKG+=("clang-${LLVM_VERSION}");
    PKG+=("lldb-${LLVM_VERSION}");
    PKG+=("lld-${LLVM_VERSION}");
    PKG+=("clangd-${LLVM_VERSION}");
elif [[ "${PKG[*]}" == "all" ]]; then
    # same as in test-install.sh
    # No worries if we have dups
    PKG=();
    PKG+=("clang-tidy-${LLVM_VERSION}");
    PKG+=("clang-format-${LLVM_VERSION}");
    PKG+=("clang-tools-${LLVM_VERSION}");
    PKG+=("clangd-${LLVM_VERSION}");
    PKG+=("llvm-${LLVM_VERSION}-dev");
    PKG+=("lld-${LLVM_VERSION}");
    PKG+=("lldb-${LLVM_VERSION}");
    PKG+=("llvm-${LLVM_VERSION}-tools");
    PKG+=("libomp-${LLVM_VERSION}-dev");
    PKG+=("libc++-${LLVM_VERSION}-dev");
    PKG+=("libc++abi-${LLVM_VERSION}-dev");
    PKG+=("libclang-common-${LLVM_VERSION}-dev");
    PKG+=("libclang-${LLVM_VERSION}-dev");
    if test "${LLVM_VERSION}" -gt 9; then
        PKG+=("libclang-cpp${LLVM_VERSION}-dev");
    fi
    if test "${LLVM_VERSION}" -gt 11; then
        PKG+=("libunwind-${LLVM_VERSION}-dev");
    fi
    if test "${LLVM_VERSION}" -gt 14; then
        PKG+=("libclang-rt-${LLVM_VERSION}-dev");
        PKG+=("libpolly-${LLVM_VERSION}-dev");
    fi
else
    declare -A version_middle=(
        ["llvm-dev"]=1
        ["llvm-tools"]=1
        ["libomp-dev"]=1
        ["libc++-dev"]=1
        ["libc++abi-dev"]=1
        ["libclang-common-dev"]=1
        ["libclang-dev"]=1
        ["libunwind-dev"]=1
        ["libclang-rt-dev"]=1
        ["libpolly-dev"]=1
    );
    declare -A version_at_end=(
        ["clang"]=1
        ["clang-tidy"]=1
        ["clang-format"]=1
        ["clang-tools"]=1
        ["clangd"]=1
        ["lld"]=1
        ["lldb"]=1
    );
    for ((i=0; i < ${#PKG[@]}; i+=1)); do
        if ! grep -q "${LLVM_VERSION}" <<< "${PKG[$i]}"; then
            if test -v version_middle["${PKG[i]}"]; then
                PKG[i]="$(sed -r "s/^(.*)-(.*)$/\1-${LLVM_VERSION}-\2/" <<< "${PKG[i]}")";
            elif test -v version_at_end["${PKG[i]}"]; then
                PKG[i]="${PKG[i]}-${LLVM_VERSION}";
            elif test "${PKG[i]}" = "libclang-cpp-dev"; then
                PKG[i]="libclang-cpp${LLVM_VERSION}-dev";
            fi
        fi
    done
fi

if test ${#PKG[@]} -gt 0; then
    apt-get update;
    apt-get install -y "${PKG[@]}";
fi
