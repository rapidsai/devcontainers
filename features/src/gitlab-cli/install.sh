#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
set -e

CLI_VERSION=${VERSION:-"latest"};

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

gitlab_cli_file_name() {
    local -;
    set -euo pipefail;

    local os="$(uname -s)";
    local arch="${TARGETARCH:-}";

    if [[ "${CLI_VERSION}" < "1.47.0" ]]; then
        arch="${arch:-$(uname -m)}";
    else
        arch="${arch:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";
        os="${os,,}";
    fi

    echo "glab_${CLI_VERSION}_${os}_${arch}.deb";
}

download_gitlab_cli_deb() {
    local -;
    set -euo pipefail;
    wget --no-hsts -q -O /tmp/gitlab-cli.deb \
        "https://gitlab.com/gitlab-org/cli/-/releases/v${CLI_VERSION}/downloads/$(gitlab_cli_file_name)";
}

# Fall back on direct download if no apt package exists
# Fetches .deb file to be installed with dpkg
install_deb_using_gitlab() {
    local -;
    set -euo pipefail;

    check_packages wget;

    # Soft version matching
    if test "${CLI_VERSION}" = latest || test "${CLI_VERSION}" = stable || test "${CLI_VERSION}" = lts; then
        find_version_from_git_tags CLI_VERSION https://gitlab.com/gitlab-org/cli;
        while ! download_gitlab_cli_deb; do
            # Handle situation where git tags are ahead of what was is available to actually download
            echo "(!) gitlab-cli version ${CLI_VERSION} failed to download. Attempting to fall back one version to retry...";
            find_prev_version_from_git_tags CLI_VERSION https://gitlab.com/gitlab-org/cli;
        done
    else
        download_gitlab_cli_deb;
    fi

    dpkg -i /tmp/gitlab-cli.deb;
    rm /tmp/gitlab-cli.deb;
}

export DEBIAN_FRONTEND=noninteractive;

# Install curl, ca-certificates, apt-transport-https, and git (if missing)
check_packages curl ca-certificates apt-transport-https;
if ! command -V git >/dev/null 2>&1; then
    check_packages git;
fi

# Install the GitHub CLI
echo "Downloading gitlab CLI...";

install_deb_using_gitlab;

glab config set -g check_update false;

if dpkg -s bash-completion >/dev/null 2>&1; then
    if command -V glab >/dev/null 2>&1; then
        glab completion -s bash | tee /etc/bash_completion.d/glab >/dev/null;
    fi
fi

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
