#!/usr/bin/env bash

if test -z "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:-}"; then
    rapids-generate-scripts;
    rapids-make-vscode-workspace --update;
fi
