#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

PKGS=(bc jq pigz sudo wget gettext-base bash-completion ca-certificates);

if ! type /usr/bin/python3 >/dev/null 2>&1; then
    PKGS+=(python3 python3-pip);
elif ! /usr/bin/python3 -m pip >/dev/null 2>&1; then
    PKGS+=(python3-pip);
fi

check_packages "${PKGS[@]}";

# Install yq if not installed
if ! type yq >/dev/null 2>&1; then
    YQ_BINARY="yq";
    YQ_BINARY+="_$(uname -s | tr '[:upper:]' '[:lower:]')";
    YQ_BINARY+="_${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";

    YQ_VERSION=latest;
    find_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    while ! wget --no-hsts -q -O- "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" | tar -C /usr/bin -zf - -x ./${YQ_BINARY} --transform="s/${YQ_BINARY}/yq/"; do
        echo "(!) YQ version ${YQ_VERSION} failed to download. Attempting to fall back one version to retry...";
        find_prev_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    done
fi

source /etc/lsb-release;

if [[ ! "23.04" > "${DISTRIB_RELEASE}" ]]; then
  BREAK_PACKAGES="--break-system-packages";
fi

# Install the rapids dependency file generator and conda-merge
/usr/bin/python3 -m pip install $BREAK_PACKAGES -U pip;
/usr/bin/python3 -m pip install $BREAK_PACKAGES rapids-dependency-file-generator conda-merge toml;

# Install RAPIDS build utility scripts to /opt/

cp -ar ./opt/rapids-build-utils /opt/;

declare -a commands=(
    checkout-same-branch
    maybe-clean-build-dir
    generate-docstring
    generate-scripts
    get-cmake-build-dir
    get-num-archs-jobs-and-load
    list-repos
    make-conda-dependencies
    make-conda-env
    make-pip-dependencies
    make-pip-env
    make-vscode-workspace
    merge-compile-commands-json
    post-attach-command
    post-start-command
    pull-repositories
    push-repositories
    python-conda-pkg-names
    python-pkg-names
    python-pkg-roots
    python-uses-rapids-build-backend
    python-uses-scikit-build
    python-uses-scikit-build-core
    query-manifest
    select-cmake-args
    select-cmake-build-args
    select-cmake-build-type
    select-cmake-define
    select-cmake-install-args
    select-cmd-args
    select-pip-install-args
    select-pip-wheel-args
    update-build-dir-links
);

# Install alternatives
for cmd in "${commands[@]}"; do
    update-alternatives --install /usr/bin/rapids-${cmd} rapids-${cmd} /opt/rapids-build-utils/bin/${cmd}.sh 0;
done

# Install bash_completion script
if type devcontainer-utils-generate-bash-completion >/dev/null 2>&1; then
    devcontainer-utils-generate-bash-completion                          \
        --out-file /etc/bash_completion.d/rapids-build-utils-completions \
        ${commands[@]/#/--command rapids-}                               \
    ;
fi

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
