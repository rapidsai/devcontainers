#!/usr/bin/env bash

_rapids_post_start_command() {
    local -;
    set -euo pipefail;

    rapids-generate-scripts;
    rapids-update-build-dir-links -j &
    rapids-make-vscode-workspace --update &
    rapids-merge-compile-commands-json > ~/compile_commands.json &
    if test -n "${PYTHON_PACKAGE_MANAGER:+x}"; then
        rapids-make-"${PYTHON_PACKAGE_MANAGER}"-env "$@";
    fi
    wait
}

if ! test -n "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:+x}"; then
    _rapids_post_start_command "$@" <&0;
fi
