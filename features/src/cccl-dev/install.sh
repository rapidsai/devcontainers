#! /usr/bin/env bash
set -e

LIT_VERSION="${LITVERSION:-latest}";

if [ "$LIT_VERSION" = "latest" ]; then
  LIT_VERSION_TO_INSTALL="lit"
else
  LIT_VERSION_TO_INSTALL="lit==$LIT_VERSION"
fi;

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

if ! command -v python >/dev/null 2>&1; then
  echo "lit feature expects python to already be installed" >&2;
  exit 1;
fi

PKG=("gettext-base" "libtbb-dev" "pbzip2");
PKG_TO_REMOVE=();

# Install gcc and g++ because we have to build psutil wheel for non-x86
if [[ "$(uname -p)" != "x86_64" ]]; then
    if ! command -v gcc >/dev/null 2>&1; then PKG_TO_REMOVE+=("gcc"); fi
    if ! command -v g++ >/dev/null 2>&1; then PKG_TO_REMOVE+=("g++"); fi
fi

check_packages "${PKG[@]}" "${PKG_TO_REMOVE[@]}";

# Find the non-root user
find_non_root_user;
USERNAME="${USERNAME:-root}";
USERHOME="$(bash -c "echo ~${USERNAME-}")";

# shellcheck disable=SC2174
mkdir -p -m 0755                          \
    "${USERHOME}/.local"                  \
    "${USERHOME}/.local/share"            \
    "${USERHOME}/.local/share/venvs"      \
    "${USERHOME}/.local/share/venvs/cccl" \
;

python -m venv "${USERHOME}/.local/share/venvs/cccl";
# shellcheck disable=SC1091
. "${USERHOME}/.local/share/venvs/cccl/bin/activate";
CC=gcc CXX=g++ python -m pip install -U pip;
CC=gcc CXX=g++ python -m pip install -U wheel setuptools;
CC=gcc CXX=g++ python -m pip install -U psutil "${LIT_VERSION_TO_INSTALL}" pre-commit;

# Ensure the user owns their homedir
chown -R "${USERNAME}:${USERNAME}" "${USERHOME}";

export USERHOME;
export LIT_VERSION="$(lit --version | grep -o -e '[0-9].*')";

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc | envsubst '$LIT_VERSION $USERHOME')";
append_to_all_bashrcs "$(cat .bashrc | envsubst '$LIT_VERSION $USERHOME')";
# export envvars in /etc/profile.d
add_etc_profile_d_script cccl-dev "$(cat .bashrc | envsubst '$LIT_VERSION $USERHOME')";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

if [[ ${#PKG_TO_REMOVE[@]} -gt 0 ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y remove "${PKG_TO_REMOVE[@]}";
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove;
fi
