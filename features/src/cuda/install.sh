#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                 \
    jq                         \
    gpg                        \
    wget                       \
    dirmngr                    \
    gpg-agent                  \
    apt-utils                  \
    gettext-base               \
    ca-certificates            \
    bash-completion            \
    software-properties-common \
    ;

echo "Downloading CUDA keyring...";

export NVARCH="$(uname -p)";
export OSNAME="$(
    . /etc/os-release;
    major="$(cut -d'.' -f1 <<< "${VERSION_ID}")";
    minor="$(cut -d'.' -f2 <<< "${VERSION_ID}")";
    echo "$ID$((major - (major % 2)))${minor}";
)";

VERSION="${CUDA_VERSION:-${VERSION:-12.5.0}}";

if [[ "$NVARCH" == aarch64 ]]; then
    NVARCH="sbsa";
fi

get_cuda_deb() {
    local deb="$(                                 \
        wget --no-hsts -q -O- "${1}/Packages"     \
    | grep -P "^Filename: \./${2}(.*)\.deb$"      \
    | sort -Vr | head -n1 | cut -d' ' -f2         \
    )";
    if [ -z "$deb" ]; then
        echo "Error: No matching .deb found for '${1}' and '${2}'" >&2
        return 1
    fi
    wget --no-hsts -q -O "/tmp/${deb#./}" "${1}/${deb#./}";
    echo -n "/tmp/${deb#./}";
}

# Add NVIDIA's keyring and apt repository
cuda_repo_base="https://developer.download.nvidia.com/compute/cuda/repos";
cuda_repo="${cuda_repo_base}/${OSNAME}/${NVARCH}";

if ! dpkg -s cuda-keyring; then
    DEBIAN_FRONTEND=noninteractive                    \
    apt install -y --no-install-recommends            \
        "$(get_cuda_deb "${cuda_repo}" cuda-keyring)" \
        ;
fi

if [[ "${OSNAME}" == "ubuntu1804" && "${NVARCH}" == "sbsa" ]]; then
    ml_repo_base="https://developer.download.nvidia.com/compute/machine-learning/repos";
    ml_repo="${ml_repo_base}/${OSNAME}/${NVARCH}";
    apt-key adv --fetch-keys "${ml_repo}/7fa2af80.pub";
    add-apt-repository -yn "deb ${ml_repo}/ /";
fi

apt-get update;

echo "Installing dev CUDA toolkit...";

export CUDA_HOME="/usr/local/cuda";

cuda_ver="${VERSION}";
cuda_ver=$(grep -Po '^[0-9]+\.[0-9]+' <<< "${cuda_ver}");
cuda_ver_major=$(grep -Po '^[0-9]+' <<< "${cuda_ver}");

cudapath="${CUDA_HOME}-${cuda_ver}";
cuda_tag="cuda${cuda_ver}";
cuda_ver="${cuda_ver/./-}";

dev_tag="";

if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
    dev_tag="-dev";
fi

PKGS=();

if [ "${INSTALLCOMPILERS:-false}" = true ]; then
    PKGS+=("cuda-nvml-dev-${cuda_ver}");
    PKGS+=("cuda-compiler-${cuda_ver}");
    PKGS+=("cuda-minimal-build-${cuda_ver}");
    PKGS+=("cuda-command-line-tools-${cuda_ver}");
    if [ "$NVARCH" = x86_64 ]; then
        PKGS+=("cuda-nvprof-${cuda_ver}");
    fi
fi

if [ "${INSTALLPROFILERS:-false}" = true ]; then
    PKGS+=("cuda-nsight-compute-${cuda_ver}");
    PKGS+=("cuda-nsight-systems-${cuda_ver}");
fi

if [ "${INSTALLCTKLIBRARIES:-false}" = true ]; then
    INSTALLCUDARUNTIME=true;
    INSTALLNVRTC=true;
    INSTALLOPENCL=true;
    INSTALLCUBLAS=true;
    INSTALLCUSPARSE=true;
    INSTALLCUFFT=true;
    INSTALLCUFILE=true;
    INSTALLCURAND=true;
    INSTALLCUSOLVER=true;
    INSTALLNPP=true;
    INSTALLNVJPEG=true;
fi

if [ "${INSTALLCUDARUNTIME:-false}" = true ]; then
    PKGS+=("cuda-cudart${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLNVRTC:-false}" = true ]; then
    PKGS+=("cuda-nvrtc${dev_tag}-${cuda_ver}");
    if test -n "$(apt-cache search "libnvjitlink${dev_tag}-${cuda_ver}" 2>/dev/null)"; then
        PKGS+=("libnvjitlink${dev_tag}-${cuda_ver}");
    fi
fi

if [ "${INSTALLOPENCL:-false}" = true ] \
&& test -n "$(apt-cache search "cuda-opencl${dev_tag}-${cuda_ver}" 2>/dev/null)"; then
    PKGS+=("cuda-opencl${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUBLAS:-false}" = true ]; then
    PKGS+=("libcublas${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUSPARSE:-false}" = true ]; then
    PKGS+=("libcusparse${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUFFT:-false}" = true ]; then
    PKGS+=("libcufft${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUFILE:-false}" = true ] \
&& test -n "$(apt-cache search "libcufile${dev_tag}-${cuda_ver}" 2>/dev/null)"; then
    PKGS+=("libcufile${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCURAND:-false}" = true ]; then
    PKGS+=("libcurand${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUSOLVER:-false}" = true ]; then
    PKGS+=("libcusolver${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLNPP:-false}" = true ]; then
    PKGS+=("libnpp${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLNVJPEG:-false}" = true ]; then
    PKGS+=("libnvjpeg${dev_tag}-${cuda_ver}");
fi

if [ "${INSTALLCUDNN:-false}" = true ]; then
    CUDNNVERSION="${CUDNNVERSION:-9}";
    if test "${CUDNNVERSION}" -le 8; then
        if test -n "$(apt-cache search "libcudnn${CUDNNVERSION:-8}" 2>/dev/null)" \
        && apt-cache policy "libcudnn${CUDNNVERSION:-8}" 2>/dev/null | grep -q "+${cuda_tag}"; then
            PKGS+=("libcudnn${CUDNNVERSION:-8}=*+${cuda_tag}");
            if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
                PKGS+=("libcudnn${CUDNNVERSION:-8}-dev=*+${cuda_tag}");
            fi
        fi
    elif test -n "$(apt-cache search "libcudnn${CUDNNVERSION}-cuda-${cuda_ver_major}" 2>/dev/null)"; then
        PKGS+=("libcudnn${CUDNNVERSION}-cuda-${cuda_ver_major}");
        if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
            PKGS+=("libcudnn${CUDNNVERSION}-dev-cuda-${cuda_ver_major}");
        fi
    fi
fi

if [ "${INSTALLNCCL:-false}" = true ] \
&& test -n "$(apt-cache search libnccl2 2>/dev/null)" \
&& apt-cache policy libnccl2 2>/dev/null | grep -q "+${cuda_tag}"; then
    PKGS+=("libnccl2=*+${cuda_tag}");
    if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
        PKGS+=("libnccl-dev=*+${cuda_tag}");
    fi
fi

if [ "${INSTALLCUTENSOR:-false}" = true ]; then
    # HACK: libcutensor-dev isn't currently in the ubuntu22.04 repo,
    # but is in ubuntu20.04. Detect this and download the 20.04 deb.
    if ! dpkg -s libcutensor-dev > /dev/null 2>&1; then
        # If `libcutensor-deb` is available in the apt repo, install it
        if ! dpkg -p libcutensor-dev 2>&1 | grep -q "not available" >/dev/null 2>&1; then
            PKGS+=("libcutensor1");
            if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
                PKGS+=("libcutensor-dev");
            fi
        else
            # If it's not in the apt repo for the current OS version, install it from the 20.04 repo
            focal_cuda_repo="${cuda_repo_base}/ubuntu2004/${NVARCH}";
            PKGS+=("$(get_cuda_deb "${focal_cuda_repo}" libcutensor1)");
            if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
                PKGS+=("$(get_cuda_deb "${focal_cuda_repo}" libcutensor-dev)");
            fi
        fi
    fi
fi

check_packages "${PKGS[@]}";
apt autoremove -y;

if ! test -L "${CUDA_HOME}"; then
    # Create /usr/local/cuda symlink
    ln -s "${cudapath}" "${CUDA_HOME}";
fi

if test -z "${CUDA_VERSION:-}"; then
    if test -f "${CUDA_HOME}/include/cuda.h"; then
        cuda_ver=$(grep "#define CUDA_VERSION" "${CUDA_HOME}/include/cuda.h" | cut -d' ' -f3);
        CUDA_VERSION_MAJOR=$((cuda_ver / 1000));
        CUDA_VERSION_MINOR=$((cuda_ver / 10 % 100));
        CUDA_VERSION_PATCH=$((cuda_ver % 10));
        CUDA_VERSION="$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR.$CUDA_VERSION_PATCH";
    else
        CUDA_VERSION="${VERSION}";
        CUDA_VERSION_MAJOR=$(cut -d'.' -f1 <<< "${VERSION}");
        CUDA_VERSION_MINOR=$(cut -d'.' -f2 <<< "${VERSION}");
        CUDA_VERSION_PATCH=$(cut -d'.' -f3 <<< "${VERSION}");
    fi
fi

export CUDA_VERSION;
export CUDA_VERSION_MAJOR;
export CUDA_VERSION_MINOR;
export CUDA_VERSION_PATCH;

if [ "${INSTALLCUTENSOR:-false}" = true ]; then
    # Remove extra libcutensor versions
    source ./prune-extra-cutensor-libs.sh;
fi

vars_=();
vars_+=('$NVARCH');
vars_+=('$CUDA_HOME');
vars_+=('$CUDA_VERSION');
vars_+=('$CUDA_VERSION_MAJOR');
vars_+=('$CUDA_VERSION_MINOR');
vars_+=('$CUDA_VERSION_PATCH');
printf -v vars_ '%s,' "${vars_[@]}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst "${vars_%,}")";
append_to_all_bashrcs "$(cat .bashrc | envsubst "${vars_%,}")";
# export envvars in /etc/profile.d
add_etc_profile_d_script cuda "$(cat .bashrc | envsubst "${vars_%,}")";

# Required for nvidia-docker v1
cat <<EOF > /etc/ld.so.conf.d/nvidia.conf
/usr/local/nvidia/lib
/usr/local/nvidia/lib64
EOF

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

rm -rf /tmp/*.deb;

if [ "${PRUNESTATICLIBS:-false}" = true ]; then
    source ./prune-static-libs.sh;
fi
