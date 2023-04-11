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

DEBIAN_FRONTEND=noninteractive                    \
apt install -y --no-install-recommends            \
    "$(get_cuda_deb "${cuda_repo}" cuda-keyring)" \
    ;

if [[ "${OSNAME}" == "ubuntu1804" && "${NVARCH}" == "sbsa" ]]; then
    ml_repo_base="https://developer.download.nvidia.com/compute/machine-learning/repos";
    ml_repo="${ml_repo_base}/${OSNAME}/${NVARCH}";
    apt-key adv --fetch-keys "${ml_repo}/7fa2af80.pub";
    add-apt-repository -yn "deb ${ml_repo}/ /"
fi

apt-get update;

echo "Installing dev CUDA toolkit..."

cuda_ver="${VERSION:-12.1.0}";
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
      cuda-nvprof-${cuda_ver} || echo ) \
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
        DEBIAN_FRONTEND=noninteractive                             \
        apt install -y --no-install-recommends                     \
            "$(get_cuda_deb "${focal_cuda_repo}" libcutensor1)"    \
            "$(get_cuda_deb "${focal_cuda_repo}" libcutensor-dev)" \
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

# Remove extra libcutensor versions
libcutensor_ver="$(dpkg -s libcutensor1 | grep '^Version:' | cut -d' ' -f2 | cut -d'-' -f1 | cut -d'.' -f4 --complement)";
libcutensorMg_shared="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensorMg.so.${libcutensor_ver}$")"
libcutensorMg_static="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensorMg_static.a$")"
libcutensor_shared="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensor.so.${libcutensor_ver}$")"
libcutensor_static="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensor_static.a$")"

libcutensorMg_shared_link="$(update-alternatives --query libcutensorMg.so.${libcutensor_ver} | grep '^Link:' | cut -d' ' -f2)";
libcutensorMg_static_link="$(update-alternatives --query libcutensorMg_static.a              | grep '^Link:' | cut -d' ' -f2)";
libcutensor_shared_link="$(update-alternatives --query libcutensor.so.${libcutensor_ver}     | grep '^Link:' | cut -d' ' -f2)";
libcutensor_static_link="$(update-alternatives --query libcutensor_static.a                  | grep '^Link:' | cut -d' ' -f2)";

# Remove existing libcutensor lib alternatives
(update-alternatives --remove-all libcutensorMg.so.${libcutensor_ver} >/dev/null 2>&1 || true);
(update-alternatives --remove-all libcutensorMg_static.a              >/dev/null 2>&1 || true);
(update-alternatives --remove-all libcutensor.so.${libcutensor_ver}   >/dev/null 2>&1 || true);
(update-alternatives --remove-all libcutensor_static.a                >/dev/null 2>&1 || true);

# Install only the alternative for the version we keep
update-alternatives --install "${libcutensorMg_shared_link}" libcutensorMg.so.${libcutensor_ver} "${libcutensorMg_shared}" 0
update-alternatives --install "${libcutensorMg_static_link}" libcutensorMg_static.a              "${libcutensorMg_static}" 0
update-alternatives --install "${libcutensor_shared_link}"   libcutensor.so.${libcutensor_ver}   "${libcutensor_shared}"   0
update-alternatives --install "${libcutensor_static_link}"   libcutensor_static.a                "${libcutensor_static}"   0

# Set the default alternative
update-alternatives --set libcutensorMg.so.${libcutensor_ver} "${libcutensorMg_shared}";
update-alternatives --set libcutensorMg_static.a              "${libcutensorMg_static}";
update-alternatives --set libcutensor.so.${libcutensor_ver}   "${libcutensor_shared}";
update-alternatives --set libcutensor_static.a                "${libcutensor_static}";

rm -rf $(find /usr/lib -mindepth 1 -type d -regex "^.*/libcutensor/.*$" | grep -Ev "^.*/libcutensor/${CUDA_VERSION_MAJOR}$");

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";

# Required for nvidia-docker v1
echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf;
echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

rm -rf /tmp/*.deb;

if [[ "${PRUNESTATICLIBS:-false}" == true ]]; then

    rm -rf "${libcutensorMg_static}" "${libcutensor_static}";
    find /usr/lib -type f -name 'libnccl_static.a' -delete || true;

    (update-alternatives --remove-all libcutensorMg_static.a >/dev/null 2>&1 || true);
    (update-alternatives --remove-all libcutensor_static.a   >/dev/null 2>&1 || true);

    for dir in "lib" "lib64"; do
        find "$(realpath -m "${CUDA_HOME}/${dir}")/" -type f \
            \( -name '*.a' ! -name 'libnvptxcompiler_static.a' ! -name 'libcudart_static.a' ! -name 'libcudadevrt.a' ! -name 'libculibos.a' \) \
            -delete || true;
    done
fi
