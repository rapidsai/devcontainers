#!/usr/bin/env bash

if ! test -n "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:+x}"; then
    rapids-generate-scripts &
    rapids-update-build-dir-links -j &
    rapids-make-vscode-workspace --update &
    rapids-merge-compile-commands-json > ~/compile_commands.json &
    if test -n "${PYTHON_PACKAGE_MANAGER:+x}"; then
        rapids-make-"${PYTHON_PACKAGE_MANAGER}"-env "$@" || true;
    fi
    wait
fi
