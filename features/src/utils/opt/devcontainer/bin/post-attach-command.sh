#! /usr/bin/env bash

if test -z "${SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND:-}"; then
    find ~/ -maxdepth 1 -exec bash -c "\
    [ \$(stat --format '%u:%g' '{}') != $(id -u):$(id -g) ] \
    && sudo chown -R $(id -u):$(id -g) {}" \;

    . devcontainer-utils-init-git;
    . devcontainer-utils-vault-s3-init;
fi
