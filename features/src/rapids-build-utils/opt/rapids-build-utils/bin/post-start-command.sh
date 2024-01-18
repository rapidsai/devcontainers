#!/usr/bin/env bash

if test -z "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:-}"; then
    rapids-make-vscode-workspace --update;
fi
