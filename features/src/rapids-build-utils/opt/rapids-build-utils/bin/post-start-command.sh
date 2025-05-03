#!/usr/bin/env bash

if ! test -n "${SKIP_RAPIDS_BUILD_UTILS_POST_START_COMMAND:+x}"; then
        time (
            rapids-generate-scripts;
            { set +x; } 2>/dev/null; echo -n "rapids-generate-scripts time:";
        ) 2>&1 & true
        time (
            rapids-update-build-dir-links -j;
            { set +x; } 2>/dev/null; echo -n "rapids-update-build-dir-links time:";
        ) 2>&1 & true
        time (
            rapids-make-vscode-workspace --update;
            { set +x; } 2>/dev/null; echo -n "rapids-make-vscode-workspace -- time:";
        ) 2>&1 & true
        time (
            rapids-merge-compile-commands-json > ~/compile_commands.json;
            { set +x; } 2>/dev/null; echo -n "rapids-merge-compile-commands-json time:";
        ) 2>&1 & true
    if test -n "${PYTHON_PACKAGE_MANAGER:+x}"; then
        rapids-make-"${PYTHON_PACKAGE_MANAGER}"-env "$@" || true;
    fi
    wait
fi
