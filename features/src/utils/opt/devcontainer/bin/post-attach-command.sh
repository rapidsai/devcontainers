#! /usr/bin/env bash

if test -n "${SKIP_POST_ATTACH_COMMAND:-}"; then
    exit 0;
fi

find ~/ -maxdepth 1 -exec bash -c "\
[ \$(stat --format '%u:%g' '{}') != $(id -u):$(id -g) ] \
&& sudo chown -R $(id -u):$(id -g) {}" \;

. devcontainer-utils-init-git;
. devcontainer-utils-vault-s3-init;
