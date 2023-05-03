#! /usr/bin/env bash
set -ex

ICC_VERSION="${VERSION:-$DEFAULT}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                  \
    gpg                         \
    dirmngr                     \
    apt-utils                   \
    gettext-base                \
    bash-completion             \
    software-properties-common  \
    ;

# Snag Intel stuff
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null;
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list;
apt-get update; apt-get install -y --no-install-recommends intel-dpcpp-cpp-compiler-${ICC_VERSION};

export PATH="$PATH:/opt/intel/oneapi/compiler/${ICC_VERSION}/linux/bin";
export ICC_VERSION="${ICC_VERSION}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
