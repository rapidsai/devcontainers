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
cuda_repo_base="https://developer.download.nvidia.com/compute/cuda/repos";
cuda_repo="${cuda_repo_base}/$(. /etc/os-release; echo "$ID${VERSION_ID/./}")/${NVARCH}";

cuda_keyring_deb="$(
    curl -s -X GET ${cuda_repo}/Packages \
  | grep -P '^Filename: \./cuda-keyring(.*)\.deb$' \
  | sort -Vr | head -n1 | cut -d' ' -f2 \
)";

cuda_keyring_deb="${cuda_keyring_deb#./}";

wget --no-hsts -q -O /tmp/${cuda_keyring_deb} "${cuda_repo}/${cuda_keyring_deb}";

dpkg -i /tmp/${cuda_keyring_deb};

apt-get update;

echo "Installing dev CUDA toolkit..."

cuda_ver="${VERSION:-12.0.0}";
cuda_ver=$(echo "${cuda_ver}" | cut -d'.' -f3 --complement);

cudapath="${CUDA_HOME}-${cuda_ver}";
cuda_ver="${cuda_ver/./-}";

check_packages                          \
    libnccl-dev                         \
    cuda-compiler-${cuda_ver}           \
    cuda-nvml-dev-${cuda_ver}           \
    cuda-libraries-dev-${cuda_ver}      \
    cuda-command-line-tools-${cuda_ver} \
    $([ "$NVARCH" == x86_64 ] && echo   \
        gds-tools-${cuda_ver} || echo ) \
    ;

# HACK: libcutensor-dev isn't currently in the ubuntu22.04 repo,
# but is in ubuntu20.04. Detect this and download the 20.04 deb.
if ! dpkg -s libcutensor-dev > /dev/null 2>&1; then
    # If `libcutensor-deb` is available in the apt repo, install it
    if ! dpkg -p libcutensor-dev 2>&1 | grep -q "not available" >/dev/null 2>&1; then
        check_packages libcutensor-dev;
    else
        # If it's not in the apt repo for the current OS version, install it from the 20.04 repo
        focal_cuda_repo="${cuda_repo_base}/ubuntu2004/${NVARCH}";
        wget --no-hsts -q -O /tmp/focal-cuda-packages "${focal_cuda_repo}/Packages";

        get_focal_cuda_deb() {
            local deb="$(                          \
                cat /tmp/focal-cuda-packages       \
            | grep -P "^Filename: \./$1(.*)\.deb$" \
            | sort -Vr | head -n1 | cut -d' ' -f2  \
            )";
            wget --no-hsts -q -O "/tmp/${deb#./}" "${focal_cuda_repo}/${deb#./}";
            echo -n "/tmp/${deb#./}";
        }

        DEBIAN_FRONTEND=noninteractive \
        apt install -y --no-install-recommends      \
            "$(get_focal_cuda_deb libcutensor1)"    \
            "$(get_focal_cuda_deb libcutensor-dev)" \
            ;
    fi
fi

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
