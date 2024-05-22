#! /usr/bin/env bash
set -ex

OPENMPI_VERSION="${VERSION:-system}";

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

ENABLE_UCX=;
ENABLE_CUDA=;

if test -n "${UCX_VERSION:-}"; then ENABLE_UCX=1; fi
if test -n "$(read_cuda_version)"; then ENABLE_CUDA=1; fi

install_openmpi_deps() {
    local -r openmpi_lib="$(
        apt-cache depends libopenmpi-dev \
      | grep -P '^  Depends:'            \
      | sed 's/^  Depends: //'           \
      | grep libopenmpi                  \
    )";

    mapfile -t run_deps < <(
        apt-cache depends "${openmpi_lib}"   \
      | grep -v -P '^  (Depends: <)'         \
      | grep -P '^  Depends:'                \
      | sed 's/^  Depends: //'               \
      | (                                    \
        if test "${ENABLE_UCX:-}" = 1;       \
        then grep -v ucx || [ "$?" == "1" ]; \
        else cat -; \
        fi \
        )  \
    );

    mapfile -t dev_deps < <(
        apt-cache depends libopenmpi-dev   \
      | grep -v -P 'openmpi'               \
      | grep -v -P '^  (Depends: <)'       \
      | grep -P '^  Depends:'              \
      | sed 's/^  Depends: //'             \
    );

    run_deps+=(build-essential gfortran);

    echo "run_deps: ${run_deps[*]}" >&2;
    echo "dev_deps: ${dev_deps[*]}" >&2;
    echo "Installing packages: ${run_deps[*]} ${dev_deps[*]}" >&2;
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "${run_deps[@]}" "${dev_deps[@]}" >&2;

    echo "${dev_deps[@]}";
}

build_and_install_openmpi() {
    mkdir /tmp/ompi;

    local -a ucx_args=();
    if test "${ENABLE_UCX:-}" = 1; then
        ucx_args+=(--with-ucx=/usr);
    fi

    local -a cuda_args=();
    if test "${ENABLE_CUDA}" = 1; then
        cuda_args+=(--with-cuda="${CUDA_HOME:-/usr/local/cuda}");
        cuda_args+=(--with-cuda-libdir="${CUDA_HOME:-/usr/local/cuda}/lib64/stubs}");
    fi

    IFS=" " read -r -a openmpi_dev_deps <<< "$(install_openmpi_deps)";

    local -r major_minor="$(grep -o '^[0-9]*.[0-9]*' <<< "${OPENMPI_VERSION}")";

    wget --no-hsts -q -O- "https://download.open-mpi.org/release/open-mpi/v${major_minor}/openmpi-${OPENMPI_VERSION}.tar.gz" \
  | tar -C /tmp/ompi -zf - --strip-components=1 -x;

    (
        cd /tmp/ompi;
        ./configure \
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
            --enable-mca-dso \
            "${ucx_args[@]}" \
            "${cuda_args[@]}";

        make -j"$(nproc --all)";
        make install;

        if test "${ENABLE_UCX:-}" = 1; then
            echo "setting MCA btl to ^ucx..."
            echo "btl = ^ucx" >> /etc/openmpi-mca-params.conf;
            echo "setting MCA pml to ^ucx..."
            echo "pml = ^ucx" >> /etc/openmpi-mca-params.conf;
            echo "setting MCA osc to ^ucx..."
            echo "osc = ^ucx" >> /etc/openmpi-mca-params.conf;
        fi

        if test "${ENABLE_CUDA}" = 1; then
            echo "setting MCA mca_base_component_show_load_errors to 0..."
            echo "mca_base_component_show_load_errors = 0" >> /etc/openmpi-mca-params.conf
            echo "setting MCA opal_warn_on_missing_libcuda to 0..."
            echo "opal_warn_on_missing_libcuda = 0" >> /etc/openmpi-mca-params.conf
            echo "setting MCA opal_cuda_support to 0..."
            echo "opal_cuda_support = 0" >> /etc/openmpi-mca-params.conf
        fi
    )

    if test ${#openmpi_dev_deps[@]} -gt 0; then
        DEBIAN_FRONTEND=noninteractive apt-get -y remove "${openmpi_dev_deps[@]}";
    fi
}

apt_get_update;
check_packages bzip2 wget ca-certificates bash-completion gettext-base pkg-config;

if test -z "${OPENMPI_VERSION:-}" || [ "${OPENMPI_VERSION:-}" = "latest" ]; then
    find_version_from_git_tags OPENMPI_VERSION https://github.com/open-mpi/ompi;
elif [ "${OPENMPI_VERSION:-}" = "system" ]; then
    OPENMPI_VERSION="$(apt-cache policy libopenmpi-dev | grep Candidate: | tr -d '[:blank:]' | cut -d: -f2 | cut -d- -f1)";
fi

if dpkg -s libopenmpi-dev > /dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get remove -y libopenmpi-dev;
fi

build_and_install_openmpi;

DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;

if test "${ENABLE_CUDA}" = 1; then
    cat <<EOF >> .bashrc
OMPI_MCA_opal_cuda_support=true
EOF
fi

if test "${ENABLE_UCX:-}" = 1; then
    cat <<EOF >> .bashrc
export OMPI_MCA_btl=ucx;
export OMPI_MCA_pml=ucx;
export OMPI_MCA_osc=ucx;
EOF

fi

export OPENMPI_VERSION;

# export envvars in bashrc files
append_to_etc_bashrc "$(envsubst < .bashrc)";
append_to_all_bashrcs "$(envsubst < .bashrc)";
# export envvars in /etc/profile.d
add_etc_profile_d_script openmpi "$(envsubst < .bashrc)";

# Clean up
# rm -rf /tmp/*;
rm -rf /tmp/ucx*;
rm -rf /tmp/ompi;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
