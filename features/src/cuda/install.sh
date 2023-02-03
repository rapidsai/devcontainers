#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages \
    jq \
    wget \
    gettext-base \
    ca-certificates \
    bash-completion \
    ;

echo "Downloading CUDA keyring...";

export NVARCH="$(uname -p)";

if [[ "$NVARCH" == aarch64 ]]; then
    NVARCH="sbsa";
fi

# Add NVIDIA's keyring and apt repository
wget --no-hsts -q -O /tmp/cuda-keyring_1.0-1_all.deb "\
https://developer.download.nvidia.com/compute/cuda/repos/\
$(. /etc/os-release; echo "$ID${VERSION_ID/./}")/\
${NVARCH}/cuda-keyring_1.0-1_all.deb";

dpkg -i /tmp/cuda-keyring_1.0-1_all.deb;

apt-get update;

echo "Installing dev CUDA toolkit..."

cuda_ver="${VERSION:-12.0.0}";
cuda_ver=$(echo "${cuda_ver}" | cut -d'.' -f3 --complement);

cudapath="${CUDA_HOME}-${cuda_ver}";
cuda_ver="${cuda_ver/./-}";

check_packages                          \
    libnccl-dev                         \
    `# cutensor isn't 22.04 repo yet?`  \
    `# libcutensor-dev`                 \
    cuda-compiler-${cuda_ver}           \
    cuda-nvml-dev-${cuda_ver}           \
    cuda-libraries-dev-${cuda_ver}      \
    cuda-command-line-tools-${cuda_ver} \
    $([ "$NVARCH" == x86_64 ] && echo   \
        gds-tools-${cuda_ver} || echo ) \
    ;

if [[ ! -L "${CUDA_HOME}" ]]; then
    # Create /usr/local/cuda symlink
    ln -s "${cudapath}" "${CUDA_HOME}";
fi

cuda_ver=$(grep "#define CUDA_VERSION" ${CUDA_HOME}/include/cuda.h | cut -d' ' -f3);
export CUDA_VERSION_MAJOR=$((cuda_ver / 1000));
export CUDA_VERSION_MINOR=$((cuda_ver / 10 % 100));
export CUDA_VERSION_PATCH=$((cuda_ver % 10));
export CUDA_VERSION="$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR.$CUDA_VERSION_PATCH";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";

# Required for nvidia-docker v1
echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf;
echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf;

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
