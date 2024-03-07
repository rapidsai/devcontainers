#!/usr/bin/env bash

export SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND=;

# shellcheck disable=SC1091
. devcontainer-utils-post-attach-command;

exec "$@";
