#! /usr/bin/env bash

if test -z "${SKIP_DEVCONTAINER_UTILS_POST_START_COMMAND:-}"; then
    sudo mkdir -m 0777 -p /var/log/devcontainer-utils;
    sudo touch /var/log/devcontainer-utils/creds-s3.log;
    sudo chmod 0777 /var/log/devcontainer-utils/creds-s3.log;

    # Fast parallel `chown -R`
    find ~/ /var/log/devcontainer-utils/ -not -user coder -print0 2>/dev/null \
  | sudo xargs -0 -r -n1 -P"$(nproc --all)" chown "$(id -u):$(id -g)" 2>/dev/null \
 || true;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git;
fi
