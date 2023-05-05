#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                  \
    gpg                         \
    lmod                        \
    wget                        \
    dpkg-dev                    \
    apt-utils                   \
    lsb-release                 \
    gettext-base                \
    bash-completion             \
    ca-certificates             \
    apt-transport-https         \
    software-properties-common  \
    ;

# Ensure lmod preceeds nvhpc's profile init
if [ -f /etc/profile.d/lmod.sh ]; then
    mv /etc/profile.d/lmod.{,_}sh;
fi

echo "Downloading NVHPC gpg key...";

wget --no-hsts -q -O- https://developer.download.nvidia.com/hpc-sdk/ubuntu/DEB-GPG-KEY-NVIDIA-HPC-SDK \
   | gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia-hpcsdk-archive-keyring.gpg;

chmod 0644 /etc/apt/trusted.gpg.d/*.gpg || true;

echo "Adding NVHPC SDK apt repository...";

# Install NVHPC-SDK apt repository
apt-add-repository -y "deb https://developer.download.nvidia.com/hpc-sdk/ubuntu/$(dpkg-architecture -q DEB_BUILD_ARCH) /";

echo "Installing NVHPC SDK...";

NVHPC_VERSION="${VERSION:-${NVHPCVERSION:-}}";
NVHPC_VERSION_YEAR=$(echo "${NVHPC_VERSION}" | cut -d'.' -f1);
NVHPC_VERSION_YEAR="20${NVHPC_VERSION_YEAR}";

DEBIAN_FRONTEND=noninteractive              \
apt-get install -y --no-install-recommends  \
    nvhpc-${NVHPC_VERSION/./-}              \
    nvhpc-${NVHPC_VERSION_YEAR}=${NVHPC_VERSION} \
    ;

export NVHPC="/opt/nvidia/hpc_sdk";
export NVHPC_VERSION="${NVHPC_VERSION}";
export NVHPC_ROOT="${NVHPC}/Linux_$(uname -p)/${NVHPC_VERSION}";
export NVHPC_CUDA_HOME="${CUDA_HOME:-$NVHPC_ROOT/cuda}";
export LIBRARY_PATH="${LIBRARY_PATH:-$NVHPC_ROOT/cuda/lib64/stubs}";

bash "${NVHPC_ROOT}/compilers/bin/makelocalrc" \
    -x "${NVHPC_ROOT}/compilers/bin" \
    -gcc "$(which gcc)" \
    -gpp "$(which g++)" \
    -g77 "$(which gfortran)";

vars_=();
vars_+=('$NVHPC');
vars_+=('$NVHPC_VERSION');
vars_+=('$NVHPC_ROOT');
vars_+=('$NVHPC_CUDA_HOME');
printf -v vars_ '%s,' "${vars_[@]}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/nvhpc.sh)";
append_to_all_bashrcs "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/nvhpc.sh)";
# export envvars in /etc/profile.d
add_etc_profile_d_script nvhpc "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/nvhpc.sh)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
