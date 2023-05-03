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


check_packages                  \
    gpg                         \
    dirmngr                     \
    apt-utils                   \
    gettext-base                \
    bash-completion             \
    gcc g++ gfortran            \
    software-properties-common  \
    ;

if ! type python >/dev/null 2>&1; then
  echo "lit feature expects python to already be installed" >&2;
  exit 1;
fi
python3 -m pip install wheel;
python3 -m pip install psutil $LIT_VERSION_TO_INSTALL;

export LIT_VERSION="$(lit --version | grep -o -e '[0-9].*')";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst)";
append_to_all_bashrcs "$(cat .bashrc | envsubst)";
# export envvars in /etc/profile.d
add_etc_profile_d_script python-lit "$(cat .bashrc | envsubst)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
