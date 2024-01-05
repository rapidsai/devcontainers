#! /usr/bin/env bash

if test -z "${SKIP_RAPIDS_BUILD_UTILS_POST_ATTACH_COMMAND:-}"; then
    if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
        rapids-make-${PYTHON_PACKAGE_MANAGER}-env || true;
    fi
fi
