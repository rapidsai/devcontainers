#! /usr/bin/env bash
set -ex

LIT_VERSION="${VERSION:-latest}";

if [ "$LIT_VERSION" -neq "latest" ]; then
  LIT_VERSION_TO_INSTALL="lit==$LIT_VERSION"
else
  LIT_VERSION_TO_INSTALL="lit"
fi;

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

if ! type python >/dev/null 2>&1; then
  echo "lit feature expects python to already be installed" >&2;
  exit 1;
fi

PKG=("gettext-base");
PKG_TO_REMOVE=();

# Install gcc and g++ because we have to build psutil wheel for non-x86
if [[ "$(uname -p)" != "x86_64" ]]; then
    if ! type gcc >/dev/null 2>&1; then PKG_TO_REMOVE+=("gcc"); fi
    if ! type g++ >/dev/null 2>&1; then PKG_TO_REMOVE+=("g++"); fi
fi

check_packages ${PKG[@]} ${PKG_TO_REMOVE[@]};

python -m pip install wheel;
python -m pip install psutil $LIT_VERSION_TO_INSTALL;

export LIT_VERSION="$(lit --version | grep -o -e '[0-9].*')";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst '$LIT_VERSION')";
append_to_all_bashrcs "$(cat .bashrc | envsubst '$LIT_VERSION')";
# export envvars in /etc/profile.d
add_etc_profile_d_script python-lit "$(cat .bashrc | envsubst '$LIT_VERSION')";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

if [[ ${#PKG_TO_REMOVE[@]} -gt 0 ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y remove ${PKG_TO_REMOVE[@]};
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
fi
