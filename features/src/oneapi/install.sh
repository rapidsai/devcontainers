#! /usr/bin/env bash
set -ex

# Intel only publishes its compilers for x86
if [[ "$(uname -p)" != "x86_64" ]]; then
    exit 0;
fi

ICC_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                  \
    gpg                         \
    lmod                        \
    wget                        \
    dirmngr                     \
    apt-utils                   \
    gettext-base                \
    software-properties-common  \
    ;

# Ensure lmod preceeds oneapi's profile init
if [ -f /etc/profile.d/lmod.sh ]; then
    mv /etc/profile.d/lmod.{,_}sh;
fi

# Add Intel repo signing key
wget --no-hsts -q -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
   | gpg --dearmor -o /etc/apt/trusted.gpg.d/oneapi-archive-keyring.gpg;

chmod 0644 /etc/apt/trusted.gpg.d/*.gpg || true;

# Add OneAPI apt repository
apt-add-repository -y "deb https://apt.repos.intel.com/oneapi all main";

if [ "$ICC_VERSION" = "latest" ]; then
    ICC_VERSION="$(apt-cache search intel-oneapi-dpcpp-cpp | cut -sd' ' -f1 | sort -rh | head -n1 | cut -sd'-' -f5)";
fi

DEBIAN_FRONTEND=noninteractive \
apt-get -y install --no-install-recommends \
    "intel-oneapi-dpcpp-cpp-${ICC_VERSION}" \
    "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-${ICC_VERSION}";

export ICC_VERSION;

vars_=();
vars_+=('$ICC_VERSION');
printf -v vars_ '%s,' "${vars_[@]}";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/oneapi.sh)";
append_to_all_bashrcs "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/oneapi.sh)";
# export envvars in /etc/profile.d
add_etc_profile_d_script oneapi "$(cat <(cat .bashrc | envsubst "${vars_%,}") etc/profile.d/oneapi.sh)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
