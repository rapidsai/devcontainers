#! /usr/bin/env bash
set -e

UCX_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages bzip2 wget ca-certificates bash-completion gettext-base pkg-config;

if test -z "${UCX_VERSION:-}" || [ "${UCX_VERSION:-}" = "latest" ]; then
    find_version_from_git_tags UCX_VERSION https://github.com/openucx/ucx;
fi

# ucx-1.15.0-rc3-ubuntu22.04-mofed5-cuda12-x86_64.tar.bz2
slug="";
slug+="ucx-";
slug+="${UCX_VERSION}-";
slug+="$(. /etc/os-release; echo "${NAME,,}${VERSION_ID}")-";

cuda="";

if test -n "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-}}"; then
    cuda=$(cut -d'.' -f1 <<< "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-}}");
    slug+="mofed5-cuda${cuda}-";
elif test -f "${CUDA_HOME:-/usr/local/cuda}/include/cuda.h"; then
    cuda=$(grep "#define CUDA_VERSION" ${CUDA_HOME:-/usr/local/cuda}/include/cuda.h | cut -d' ' -f3);
    cuda=$((cuda / 1000));
    slug+="mofed5-cuda${cuda}-";
fi

slug+="$(uname -p)";

mkdir /tmp/ucx;

# https://github.com/openucx/ucx/releases/download/v1.15.0-rc3/ucx-1.15.0-rc3-ubuntu22.04-mofed5-cuda12-x86_64.tar.bz2
if wget --no-hsts -q -O /tmp/ucx.tar.bz2 "https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/${slug}.tar.bz2"; then
    tar -C /tmp/ucx -xvjf /tmp/ucx.tar.bz2;
    apt_get_update;
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install --no-install-recommends /tmp/ucx/*.deb || true;
    apt-get -y --fix-broken install;
else
    PKG=(pkg-config libibverbs1 librdmacm1 libnuma1 numactl);
    PKG+=(git libtool automake libnuma-dev librdmacm-dev libibverbs-dev);
    PKG_TO_REMOVE=(git libtool automake libnuma-dev librdmacm-dev libibverbs-dev);

    build_cmd="";

    if ! type gcc >/dev/null 2>&1; then
        PKG+=(build-essential);
        PKG_TO_REMOVE+=(build-essential);
    fi

    if type make >/dev/null 2>&1; then
        build_cmd="make";
    elif type ninja >/dev/null 2>&1; then
        build_cmd="ninja";
    else
        build_cmd="make";
        PKG+=($build_cmd);
        PKG_TO_REMOVE+=($build_cmd);
    fi

    check_packages ${PKG[@]};

    git clone https://github.com/openucx/ucx.git /tmp/ucx --depth 1 --branch "v${UCX_VERSION}";

    (
        cd /tmp/ucx;
        ./autogen.sh;
        ./contrib/configure-release \
            --enable-mt \
            --enable-cma \
            --enable-numa \
            --with-verbs \
            --with-rdmacm \
            --with-gnu-ld \
            ${cuda:+--with-cuda=${CUDA_HOME:-/usr/local/cuda}};

        $build_cmd -j$(nproc --ignore=2);
        $build_cmd install;
    )

    if test ${#PKG_TO_REMOVE[@]} -gt 0; then
        DEBIAN_FRONTEND=noninteractive apt-get -y remove ${PKG_TO_REMOVE[@]};
        DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
    fi
fi

export UCX_VERSION;

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";
# export envvars in /etc/profile.d
add_etc_profile_d_script ucx "$(cat .bashrc | envsubst)";

# Clean up
# rm -rf /tmp/*;
rm -rf /tmp/ucx*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
