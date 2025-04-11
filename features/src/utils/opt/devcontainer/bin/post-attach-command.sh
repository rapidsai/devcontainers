#! /usr/bin/env bash

if ! test -n "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:+x}"; then
    # shellcheck disable=SC1091
    . devcontainer-utils-init-git-interactive;
    # shellcheck disable=SC1091
    . devcontainer-utils-creds-s3-init;
fi
