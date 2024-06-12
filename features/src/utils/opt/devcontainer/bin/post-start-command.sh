#! /usr/bin/env bash

if test -z "${SKIP_DEVCONTAINER_UTILS_POST_START_COMMAND:-}"; then
    # Fast parallel `chown -R`
    find ~/ -not -user coder -print0 2>/dev/null \
  | sudo xargs -0 -r -n1 -P"$(nproc --all)" chown "$(id -u):$(id -g)" 2>/dev/null \
 || true;

    # shellcheck disable=SC1091
    . devcontainer-utils-init-git;
fi
