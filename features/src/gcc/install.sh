#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                  \
    gpg                         \
    dirmngr                     \
    gpg-agent                   \
    apt-utils                   \
    gettext-base                \
    ca-certificates             \
    bash-completion             \
    gcc g++ gfortran            \
    apt-transport-https         \
    software-properties-common  \
    ;

GCC_VERSION_DEFAULT="$(gcc -dumpversion)";
GCC_VERSION="${VERSION:-${GCC_VERSION_DEFAULT}}";

if [[ "${GCC_VERSION}" != "${GCC_VERSION_DEFAULT}" ]]; then
    apt-add-repository -y ppa:ubuntu-toolchain-r/ppa;
    # Install gcc-${GCC_VERSION}
    DEBIAN_FRONTEND=noninteractive              \
    apt-get install -y --no-install-recommends  \
        {gcc,g++,gfortran}-${GCC_VERSION}       \
        ;

    # Install gcc/g++ alternatives
    update-alternatives                                                       \
        --install /usr/bin/gcc      gcc      $(which gcc-${GCC_VERSION}) 30   \
        --slave   /usr/bin/g++      g++      $(which g++-${GCC_VERSION})      \
        --slave   /usr/bin/gcov     gcov     $(which gcov-${GCC_VERSION})     \
        --slave   /usr/bin/gfortran gfortran $(which gfortran-${GCC_VERSION}) \
        ;
fi

export GCC_VERSION;

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";
# export envvars in /etc/profile.d
add_etc_profile_d_script gcc "$(cat .bashrc | envsubst)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
