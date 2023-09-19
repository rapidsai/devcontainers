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
export OSNAME="$(. /etc/os-release; echo "$ID${VERSION_ID/./}")";

if [[ "$NVARCH" == aarch64 ]]; then
    NVARCH="sbsa";
fi

get_cuda_deb() {
    local deb="$(                                 \
        wget --no-hsts -q -O- "${1}/Packages"     \
    | grep -P "^Filename: \./${2}(.*)\.deb$"      \
    | sort -Vr | head -n1 | cut -d' ' -f2         \
    )";
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

cuda_ver="${VERSION:-12.2.0}";
cuda_ver=$(echo "${cuda_ver}" | cut -d'.' -f3 --complement);

cudapath="${CUDA_HOME}-${cuda_ver}";
cuda_tag="cuda${cuda_ver}";
cuda_ver="${cuda_ver/./-}";

dev_pkgs=();
runtime_pkgs=();
runtime_pkgs+=("cuda-libraries-${cuda_ver}");

if [ "${INSTALLCUDNN:-false}" = true ]; then
    runtime_pkgs+=("libcudnn8=*+${cuda_tag}");
fi

if [ "${INSTALLNCCL:-false}" = true ]; then
    runtime_pkgs+=("libnccl2=*+${cuda_tag}");
fi

if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
    dev_pkgs+=();
    dev_pkgs+=("cuda-compiler-${cuda_ver}");
    dev_pkgs+=("libnccl-dev=*+${cuda_tag}");
    dev_pkgs+=("cuda-nvml-dev-${cuda_ver}");
    dev_pkgs+=("cuda-libraries-dev-${cuda_ver}");
    dev_pkgs+=("cuda-nsight-systems-${cuda_ver}");
    dev_pkgs+=("cuda-command-line-tools-${cuda_ver}");

    if [ "$NVARCH" = x86_64 ]; then
        runtime_pkgs+=("cuda-nvprof-${cuda_ver}");
    fi

    if [ "${INSTALLCUDNN:-false}" = true ]; then
        dev_pkgs+=("libcudnn8-dev=*+${cuda_tag}");
    fi

    if [ "${INSTALLNCCL:-false}" = true ]; then
        dev_pkgs+=("libnccl2=*+${cuda_tag}");
    fi
fi

if [ "${INSTALLCUTENSOR:-false}" = true ]; then
    # HACK: libcutensor-dev isn't currently in the ubuntu22.04 repo,
    # but is in ubuntu20.04. Detect this and download the 20.04 deb.
    if ! dpkg -s libcutensor-dev > /dev/null 2>&1; then
        # If `libcutensor-deb` is available in the apt repo, install it
        if ! dpkg -p libcutensor-dev 2>&1 | grep -q "not available" >/dev/null 2>&1; then
            runtime_pkgs+=(libcutensor1);
            if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
                dev_pkgs+=(libcutensor-dev);
            fi
        else
            # If it's not in the apt repo for the current OS version, install it from the 20.04 repo
            focal_cuda_repo="${cuda_repo_base}/ubuntu2004/${NVARCH}";
            runtime_pkgs+=("$(get_cuda_deb "${focal_cuda_repo}" libcutensor1)");
            if [ "${INSTALLDEVPACKAGES:-false}" = true ]; then
                dev_pkgs+=("$(get_cuda_deb "${focal_cuda_repo}" libcutensor-dev)");
            fi
        fi
    fi
fi

check_packages ${runtime_pkgs[@]} ${dev_pkgs[@]};

if ! test -L "${CUDA_HOME}"; then
    # Create /usr/local/cuda symlink
    ln -s "${cudapath}" "${CUDA_HOME}";
fi

cuda_ver=$(grep "#define CUDA_VERSION" ${CUDA_HOME}/include/cuda.h | cut -d' ' -f3);
export CUDA_VERSION_MAJOR=$((cuda_ver / 1000));
export CUDA_VERSION_MINOR=$((cuda_ver / 10 % 100));
export CUDA_VERSION_PATCH=$((cuda_ver % 10));
export CUDA_VERSION="$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR.$CUDA_VERSION_PATCH";

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
echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf;
echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

rm -rf /tmp/*.deb;

if [ "${PRUNESTATICLIBS:-false}" = true ]; then
    source ./prune-static-libs.sh;
fi
