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

# Fall back on direct download if no apt package exists
# Fetches .deb file to be installed with dpkg
install_deb_using_gitlab() {
    check_packages wget;
    arch="${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";
    if [[ "$arch" == amd64 ]]; then
        arch=x86_64;
    fi

    find_version_from_git_tags CLI_VERSION https://gitlab.com/gitlab-org/cli;
    cli_filename="glab_${CLI_VERSION}_Linux_${arch}.deb";

    mkdir -p /tmp/glabcli;
    pushd /tmp/glabcli;
    wget https://gitlab.com/gitlab-org/cli/-/releases/v${CLI_VERSION}/downloads/${cli_filename};
    exit_code=$?;
    set -e;
    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) gitlab-cli version ${CLI_VERSION} failed to download. Attempting to fall back one version to retry...";
        find_prev_version_from_git_tags CLI_VERSION https://gitlab.com/gitlab-org/cli;
        wget https://gitlab.com/gitlab-org/cli/-/releases/v${CLI_VERSION}/downloads/${cli_filename};
    fi

    dpkg -i /tmp/glabcli/${cli_filename};
    popd;
    rm -rf /tmp/glabcli;
}

export DEBIAN_FRONTEND=noninteractive;

# Install curl, apt-transport-https, curl, or git if missing
check_packages curl ca-certificates apt-transport-https;
if ! type git > /dev/null 2>&1; then
    check_packages git;
fi

# Soft version matching
if [ "${CLI_VERSION}" != "latest" ] && [ "${CLI_VERSION}" != "lts" ] && [ "${CLI_VERSION}" != "stable" ]; then
    find_version_from_git_tags CLI_VERSION "https://gitlab.com/gitlab-org/cli";
fi

# Install the GitHub CLI
echo "Downloading gitlab CLI...";

install_deb_using_gitlab;

if dpkg -s bash-completion >/dev/null 2>&1; then
    if type glab >/dev/null 2>&1; then
        glab completion -s bash | tee /etc/bash_completion.d/glab >/dev/null;
    fi
fi

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
