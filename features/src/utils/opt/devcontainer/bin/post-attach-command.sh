#! /usr/bin/env bash

if test -z "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:-}"; then
    find ~/ -maxdepth 1 -exec bash -c '\
    [ $(stat -c "%u:%g" "$0") != "$1" ] && \
    sudo chown -R "$1" "$0"' {} "$(id -u):$(id -g)" \;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git;
    # shellcheck disable=SC1091
    . devcontainer-utils-vault-s3-init;
fi
