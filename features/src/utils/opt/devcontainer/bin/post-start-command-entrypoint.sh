#!/usr/bin/env bash

export SKIP_DEVCONTAINER_UTILS_POST_START_COMMAND=;

# shellcheck disable=SC1091
. devcontainer-utils-post-start-command;

exec "$@";
