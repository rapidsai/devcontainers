#! /usr/bin/env bash

if ! test -n "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:+x}"; then
    sudo mkdir -m 0777 -p /var/log/devcontainer-utils;
    sudo touch /var/log/devcontainer-utils/creds-s3.log;
    sudo chmod 0777 /var/log/devcontainer-utils/creds-s3.log;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git-interactive;

    # Reset sccache-dist configuration
    SCCACHE_DIST_URL= devcontainer-utils-configure-sccache-dist;

    # Maybe load sccache client credentials
    # shellcheck disable=SC1091
    . devcontainer-utils-creds-s3-init;

    # Update sccache client configuration to enable/disable sccache-dist
    if test -n "${DEVCONTAINER_UTILS_ENABLE_SCCACHE_DIST:+x}"; then
        devcontainer-utils-install-sccache                   \
            --repo "${SCCACHE_REPOSITORY:-rapidsai/sccache}" \
            --version "${SCCACHE_VERSION:-rapids}"           \
        ;
        if test -n "${SCCACHE_DIST_AUTH_TOKEN:+x}"; then
            devcontainer-utils-init-sccache-dist        \
                --enable-sccache-dist - <<< "           \
                --auth-type 'token'                     \
                --auth-token '$SCCACHE_DIST_AUTH_TOKEN' \
            ";
        elif test -n "${SCCACHE_DIST_AUTH_TOKEN_VAR:+x}"; then
            devcontainer-utils-init-sccache-dist               \
                --enable-sccache-dist - <<< "                  \
                --auth-type 'token'                            \
                --auth-token '${!SCCACHE_DIST_AUTH_TOKEN_VAR}' \
            ";
        else
            # Update ~/.config/sccache/config to use gh token auth
            devcontainer-utils-init-sccache-dist --enable-sccache-dist-with-github-auth;
        fi
    fi
fi
