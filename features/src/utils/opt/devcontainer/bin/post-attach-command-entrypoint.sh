#!/usr/bin/env bash

SKIP_DEVCONTAINER_UTILS_POST_ATTACH_COMMAND=;

. devcontainer-utils-post-attach-command;

exec "$@";
