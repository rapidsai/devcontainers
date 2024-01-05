#! /usr/bin/env bash

if test -n "${SKIP_POST_ATTACH_COMMAND:-}"; then
    exit 0;
fi

if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
    rapids-make-${PYTHON_PACKAGE_MANAGER}-env || true;
fi
