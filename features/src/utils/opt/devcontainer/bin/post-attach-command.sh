#! /usr/bin/env bash

if ! test -n "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:+x}"; then
    sudo mkdir -m 0777 -p /var/log/devcontainer-utils;
    sudo touch /var/log/devcontainer-utils/creds-s3.log;
    sudo chmod 0777 /var/log/devcontainer-utils/creds-s3.log;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git-interactive;

    # Reset sccache-dist configuration
    devcontainer-utils-init-sccache-dist;

    # Initialize the GitHub CLI with the appropriate user scopes
    # shellcheck disable=SC1091
    . devcontainer-utils-creds-s3-init;

    # Update sccache client configuration to enable/disable sccache-dist
    if test -n "${DEVCONTAINER_UTILS_ENABLE_SCCACHE_DIST:+x}"; then
        if test -n "${SCCACHE_DIST_TOKEN:+x}"; then
            devcontainer-utils-install-sccache --repo trxcllnt/sccache;
            # Update ~/.config/sccache/config to use $SCCACHE_DIST_TOKEN
            devcontainer-utils-init-sccache-dist     \
                --enable-sccache-dist - <<< "        \
                --auth-type 'token'                  \
                --auth-token '${SCCACHE_DIST_TOKEN}' \
            ";
        elif gh auth status >/dev/null 2>&1; then
            devcontainer-utils-install-sccache --repo trxcllnt/sccache;
            # Update ~/.config/sccache/config to use gh token auth
            devcontainer-utils-init-sccache-dist --enable-with-github-auth;
        fi
    fi
fi
