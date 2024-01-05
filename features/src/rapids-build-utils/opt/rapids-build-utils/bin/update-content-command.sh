#! /usr/bin/env bash

if test -n "${SKIP_UPDATE_CONTENT_COMMAND:-}"; then
    exit 0;
fi

rapids-generate-scripts;

rapids-make-vscode-workspace --update;
