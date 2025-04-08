#!/usr/bin/env bash

if test -z "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:-}"; then
    rapids-generate-scripts;
    rapids-update-build-dir-links -j;
    rapids-make-vscode-workspace --update;
    rapids-merge-compile-commands-json > ~/compile_commands.json;
    if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
        rapids-make-"${PYTHON_PACKAGE_MANAGER}"-env "$@" || true;
    fi
fi
