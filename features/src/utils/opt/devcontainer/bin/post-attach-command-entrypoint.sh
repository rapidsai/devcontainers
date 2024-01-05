#!/usr/bin/env bash

SKIP_POST_ATTACH_COMMAND=;

. devcontainer-utils-post-attach-command;

exec "$@";
