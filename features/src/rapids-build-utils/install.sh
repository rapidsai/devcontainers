#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages bc jq sudo wget gettext-base bash-completion ca-certificates;

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

# Install the rapids dependency file generator and conda-merge
if type python >/dev/null 2>&1; then
    python -m pip install 'rapids-dependency-file-generator<1.14' conda-merge toml;
fi

# Install RAPIDS build utility scripts to /opt/

cp -ar ./opt/rapids-build-utils /opt/;

update-alternatives --install /usr/bin/rapids-update-content-command        rapids-update-content-command       /opt/rapids-build-utils/bin/update-content-command.sh       0;
update-alternatives --install /usr/bin/rapids-post-start-command            rapids-post-start-command           /opt/rapids-build-utils/bin/post-start-command.sh           0;
update-alternatives --install /usr/bin/rapids-post-attach-command           rapids-post-attach-command          /opt/rapids-build-utils/bin/post-attach-command.sh          0;
update-alternatives --install /usr/bin/rapids-checkout-same-branch          rapids-checkout-same-branch         /opt/rapids-build-utils/bin/checkout-same-branch.sh         0;
update-alternatives --install /usr/bin/rapids-pull-repositories             rapids-pull-repositories            /opt/rapids-build-utils/bin/pull-repositories.sh            0;
update-alternatives --install /usr/bin/rapids-push-repositories             rapids-push-repositories            /opt/rapids-build-utils/bin/push-repositories.sh            0;
update-alternatives --install /usr/bin/rapids-generate-scripts              rapids-generate-scripts             /opt/rapids-build-utils/bin/generate-scripts.sh             0;
update-alternatives --install /usr/bin/rapids-join-strings                  rapids-join-strings                 /opt/rapids-build-utils/bin/join-strings.sh                 0;
update-alternatives --install /usr/bin/rapids-make-conda-env                rapids-make-conda-env               /opt/rapids-build-utils/bin/make-conda-env.sh               0;
update-alternatives --install /usr/bin/rapids-make-pip-env                  rapids-make-pip-env                 /opt/rapids-build-utils/bin/make-pip-env.sh                 0;
update-alternatives --install /usr/bin/rapids-make-vscode-workspace         rapids-make-vscode-workspace        /opt/rapids-build-utils/bin/make-vscode-workspace.sh        0;
update-alternatives --install /usr/bin/rapids-parse-cmake-args              rapids-parse-cmake-args             /opt/rapids-build-utils/bin/parse-cmake-args.sh             0;
update-alternatives --install /usr/bin/rapids-parse-cmake-build-type        rapids-parse-cmake-build-type       /opt/rapids-build-utils/bin/parse-cmake-build-type.sh       0;
update-alternatives --install /usr/bin/rapids-parse-cmake-var-from-args     rapids-parse-cmake-var-from-args    /opt/rapids-build-utils/bin/parse-cmake-var-from-args.sh    0;
update-alternatives --install /usr/bin/rapids-parse-cmake-vars-from-args    rapids-parse-cmake-vars-from-args   /opt/rapids-build-utils/bin/parse-cmake-vars-from-args.sh   0;
update-alternatives --install /usr/bin/rapids-python-pkg-roots              rapids-python-pkg-roots             /opt/rapids-build-utils/bin/python-pkg-roots.sh             0;
update-alternatives --install /usr/bin/rapids-python-pkg-names              rapids-python-pkg-names             /opt/rapids-build-utils/bin/python-pkg-names.sh             0;
update-alternatives --install /usr/bin/rapids-python-conda-pkg-names        rapids-python-conda-pkg-names       /opt/rapids-build-utils/bin/python-conda-pkg-names.sh       0;
update-alternatives --install /usr/bin/rapids-get-num-archs-jobs-and-load   rapids-get-num-archs-jobs-and-load  /opt/rapids-build-utils/bin/get-num-archs-jobs-and-load.sh  0;
update-alternatives --install /usr/bin/rapids-list-repos                    rapids-list-repos                   /opt/rapids-build-utils/bin/list-repos.sh                   0;

find /opt/rapids-build-utils \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Copy in bash completions
mkdir -p /etc/bash_completion.d/;
cp -ar ./etc/bash_completion.d/* /etc/bash_completion.d/;

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
