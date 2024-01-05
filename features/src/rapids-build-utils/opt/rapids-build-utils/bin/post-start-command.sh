#! /usr/bin/env bash

if test -n "${SKIP_POST_START_COMMAND:-}"; then
    exit 0;
fi

rapids-make-vscode-workspace --update;
