#! /usr/bin/env bash

if ! test -n "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:+x}"; then
    sudo mkdir -m 0777 -p /var/log/devcontainer-utils;
    sudo touch /var/log/devcontainer-utils/creds-s3.log;
    sudo chmod 0777 /var/log/devcontainer-utils/creds-s3.log;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git-interactive;

    # Reset sccache-dist configuration
    SCCACHE_DIST_URL= devcontainer-utils-configure-sccache-dist;

    # Initialize the GitHub CLI with the appropriate user scopes
    # and load credentials for the sccache client
    # shellcheck disable=SC1091
    . devcontainer-utils-creds-s3-init;

    # Update sccache client configuration to enable/disable sccache-dist
    if test -n "${DEVCONTAINER_UTILS_ENABLE_SCCACHE_DIST:+x}"; then
        devcontainer-utils-install-sccache --repo trxcllnt/sccache;
        if  ! test -n "${SCCACHE_DIST_AUTH_TOKEN:+x}" && gh auth status >/dev/null 2>&1; then
            # Update ~/.config/sccache/config to use gh token auth
            devcontainer-utils-init-sccache-dist --enable-with-github-auth;
        else
            devcontainer-utils-init-sccache-dist;
        fi
    fi
fi
