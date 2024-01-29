#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages bc jq sudo wget gettext-base bash-completion ca-certificates;

# Install yq if not installed
if ! type yq >/dev/null 2>&1; then
    YQ_VERSION=latest;
    find_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;

    YQ_BINARY="yq";
    YQ_BINARY+="_$(uname -s | tr '[:upper:]' '[:lower:]')";
    YQ_BINARY+="_${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";

    wget --no-hsts -q -O- "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" \
        | tar -C /usr/bin -zf - -x ./${YQ_BINARY} --transform="s/${YQ_BINARY}/yq/";
fi

source /etc/lsb-release;

if [[ ! "23.04" > "${DISTRIB_RELEASE}" ]]; then
  BREAK_PACKAGES="--break-system-packages";
fi

# Install the rapids dependency file generator and conda-merge
if type python >/dev/null 2>&1; then
    python -m pip install $BREAK_PACKAGES rapids-dependency-file-generator conda-merge toml;
fi

# Install RAPIDS build utility scripts to /opt/

cp -ar ./opt/rapids-build-utils /opt/;

install_utility() {
    local cmd="rapids-${1}";
    local src="${2:-"${1}.sh"}";
    # Install alternative
    update-alternatives --install /usr/bin/${cmd} ${cmd} /opt/rapids-build-utils/bin/${src} 0;

    # Install bash_completion script
    if type devcontainer-utils-generate-bash-completion >/dev/null 2>&1; then
        devcontainer-utils-generate-bash-completion --command "${cmd}" --out-dir /etc/bash_completion.d;
    fi
}

install_utility update-content-command;
install_utility post-start-command;
install_utility post-attach-command;

install_utility checkout-same-branch;
install_utility pull-repositories;
install_utility push-repositories;
install_utility generate-scripts;
install_utility make-conda-dependencies;
install_utility make-conda-env;
install_utility make-pip-dependencies;
install_utility make-pip-env;
install_utility make-vscode-workspace;
install_utility parse-cmake-args;
install_utility parse-cmake-build-type;
install_utility parse-cmake-var-from-args;
install_utility parse-cmake-vars-from-args;
install_utility python-pkg-roots;
install_utility python-pkg-names;
install_utility python-conda-pkg-names;
install_utility get-num-archs-jobs-and-load;
install_utility list-repos;
install_utility query-manifest;

find /opt/rapids-build-utils \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Create bash completions
mkdir -p /etc/bash_completion.d/;

yq shell-completion bash | tee /etc/bash_completion.d/yq >/dev/null;

# Activate venv in /etc/bash.bashrc
append_to_etc_bashrc "$(cat .bashrc)";
# Activate venv in ~/.bashrc
append_to_all_bashrcs "$(cat .bashrc)";
# export envvars in /etc/profile.d
add_etc_profile_d_script rapids-build-utils "$(cat .bashrc)";

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
