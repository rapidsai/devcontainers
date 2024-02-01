#!/usr/bin/env bash

export SKIP_RAPIDS_BUILD_UTILS_POST_ATTACH_COMMAND=;

# shellcheck disable=SC1091
. rapids-post-attach-command;

exec "$@";
