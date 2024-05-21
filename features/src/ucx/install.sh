#! /usr/bin/env bash
set -e

UCX_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

read_cuda_version() {
    local cuda="";

    if test -n "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-}}"; then
        cuda=$(cut -d'.' -f1 <<< "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-}}");
    elif test -f "${CUDA_HOME:-/usr/local/cuda}/include/cuda.h"; then
        cuda=$(grep "#define CUDA_VERSION" ${CUDA_HOME:-/usr/local/cuda}/include/cuda.h | cut -d' ' -f3);
        cuda=$((cuda / 1000));
    fi

    echo "${cuda}";
}

download_ucx_release() {

    # ucx-1.15.0-rc3-ubuntu22.04-mofed5-cuda12-x86_64.tar.bz2
    local slug="";
    slug+="ucx";
    slug+="-${UCX_VERSION}";
    slug+="-$(. /etc/os-release; echo "${NAME,,}${VERSION_ID}")";

    local cuda="$(read_cuda_version)";

    if test -n "${cuda}"; then
        slug+="-mofed5-cuda${cuda}";
    fi

    if [ "$(uname -p)" = "x86_64" ]; then
        # https://github.com/openucx/ucx/releases/download/v1.15.0-rc3/ucx-1.15.0-rc3-ubuntu22.04-mofed5-cuda12-x86_64.tar.bz2
        if ! wget --no-hsts -q -O /tmp/ucx.tar.bz2 "https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/${slug}-$(uname -p).tar.bz2"; then
            # https://github.com/openucx/ucx/releases/download/v1.14.1/ucx-1.14.1-ubuntu22.04-mofed5-cuda12.tar.bz2
            wget --no-hsts -q -O /tmp/ucx.tar.bz2 "https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/${slug}.tar.bz2";
        fi
    else
        wget --no-hsts -q -O /tmp/ucx.tar.bz2 "https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/${slug}-$(uname -p).tar.bz2";
    fi
}

install_ucx_release() {
    mkdir /tmp/ucx;
    tar -C /tmp/ucx -xvjf /tmp/ucx.tar.bz2;
    apt_get_update;
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install --no-install-recommends /tmp/ucx/*.deb || true;
    apt-get -y --fix-broken install;
}

install_build_deps() {
    local PKG=(git libevent-dev libibverbs1 librdmacm1 libnuma1 numactl);
    local PKG_TO_REMOVE=();

    if ! dpkg -s gfortran > /dev/null 2>&1; then PKG_TO_REMOVE+=(gfortran); fi;
    if ! dpkg -s libtool > /dev/null 2>&1; then PKG_TO_REMOVE+=(libtool); fi;
    if ! dpkg -s automake > /dev/null 2>&1; then PKG_TO_REMOVE+=(automake); fi;
    if ! dpkg -s zlib1g-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(zlib1g-dev); fi;
    if ! dpkg -s libnl-3-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(libnl-3-dev); fi;
    if ! dpkg -s libhwloc-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(libhwloc-dev); fi;
    if ! dpkg -s libnuma-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(libnuma-dev); fi;
    if ! dpkg -s librdmacm-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(librdmacm-dev); fi;
    if ! dpkg -s libibverbs-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(libibverbs-dev); fi;
    if ! dpkg -s libibverbs-dev > /dev/null 2>&1; then PKG_TO_REMOVE+=(libibverbs-dev); fi;
    if ! dpkg -s build-essential > /dev/null 2>&1; then PKG_TO_REMOVE+=(build-essential); fi;

    check_packages ${PKG[@]} ${PKG_TO_REMOVE[@]} >&2;

    echo "${PKG_TO_REMOVE[@]}";
}

build_and_install_ucx() {
    local cuda="$(read_cuda_version)";

    mkdir /tmp/ucx;

    git clone https://github.com/openucx/ucx.git /tmp/ucx --depth 1 --branch "v${UCX_VERSION}";

    (
        cd /tmp/ucx;
        ./autogen.sh;
        ./contrib/configure-release \
            --enable-mt             \
            --enable-cma            \
            --enable-numa           \
            --with-verbs            \
            --with-xpmem            \
            --with-rdmacm           \
            ${cuda:+--with-cuda=${CUDA_HOME:-/usr/local/cuda}};

        make -j$(nproc --all);
        make install;
    )
}

build_and_install_openmpi_for_ucx() {
    mkdir /tmp/ompi;

    local cuda="$(read_cuda_version)";

    git clone https://github.com/open-mpi/ompi.git /tmp/ompi --depth 1 --branch "v${OPENMPI_VERSION}";

    (
        cd /tmp/ompi;
        ./autogen.pl;
        mkdir build
        cd build;
        ../configure \
            --prefix=/usr \
            --disable-dependency-tracking \
            --enable-mpi-fortran \
            --disable-wrapper-rpath \
            --disable-wrapper-runpath \
            --with-wrapper-cflags="-I/usr/include" \
            --with-wrapper-cxxflags="-I/usr/include" \
            --with-wrapper-fcflags="-I/usr/include" \
            --with-wrapper-ldflags="-L/usr/lib -Wl,-rpath,/usr/lib" \
            --with-sge \
            --with-hwloc=/usr \
            --with-libevent=/usr \
            --with-zlib=/usr \
            --with-ucx=/usr \
            --enable-mca-dso \
            ${cuda:+--with-cuda=${CUDA_HOME:-/usr/local/cuda}} \
            ${cuda:+--with-cuda-libdir=${CUDA_HOME:-/usr/local/cuda}/lib64/stubs};

        make -j"$(nproc --all)";
        make install;

        echo "setting MCA btl to ^ucx..."
        echo "btl = ^ucx" >> /etc/openmpi-mca-params.conf;
        echo "setting MCA pml to ^ucx..."
        echo "pml = ^ucx" >> /etc/openmpi-mca-params.conf;
        echo "setting MCA osc to ^ucx..."
        echo "osc = ^ucx" >> /etc/openmpi-mca-params.conf;

        if test -n "${cuda-}"; then
            echo "setting MCA mca_base_component_show_load_errors to 0..."
            echo "mca_base_component_show_load_errors = 0" >> /etc/openmpi-mca-params.conf
            echo "setting MCA opal_warn_on_missing_libcuda to 0..."
            echo "opal_warn_on_missing_libcuda = 0" >> /etc/openmpi-mca-params.conf
            echo "setting MCA opal_cuda_support to 0..."
            echo "opal_cuda_support = 0" >> /etc/openmpi-mca-params.conf
        fi
    )
}

check_packages bzip2 wget ca-certificates bash-completion gettext-base pkg-config;

if test -z "${UCX_VERSION:-}" || [ "${UCX_VERSION:-}" = "latest" ]; then
    find_version_from_git_tags UCX_VERSION https://github.com/openucx/ucx;
fi

OPENMPI_VERSION=
BUILD_OPENMPI_FOR_UCX=

if dpkg -s libopenmpi-dev > /dev/null 2>&1; then
    BUILD_OPENMPI_FOR_UCX=1;
    OPENMPI_VERSION="$(apt-cache policy libopenmpi-dev | grep Installed: | tr -d '[:blank:]' | cut -d: -f2 | cut -d- -f1)";
    DEBIAN_FRONTEND=noninteractive apt remove -y libopenmpi-dev;
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
fi

declare -a PKG_TO_REMOVE;

if download_ucx_release; then
    install_ucx_release;
else
    mapfile -t PKG_TO_REMOVE < <(install_build_deps);
    build_and_install_ucx;
fi

if test -n "${BUILD_OPENMPI_FOR_UCX:-}"; then
    mapfile -t PKG_TO_REMOVE < <(install_build_deps);
    build_and_install_openmpi_for_ucx;
    export OMPI_MCA_btl=ucx;
    export OMPI_MCA_pml=ucx;
    export OMPI_MCA_osc=ucx;
    export OPENMPI_VERSION;
fi

if test ${#PKG_TO_REMOVE[@]} -gt 0; then
    DEBIAN_FRONTEND=noninteractive apt-get -y remove "${PKG_TO_REMOVE[@]}";
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
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
rm -rf /tmp/ompi;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
