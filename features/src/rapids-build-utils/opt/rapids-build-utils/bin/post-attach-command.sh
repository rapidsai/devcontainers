#! /usr/bin/env bash

if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
    rapids-make-${PYTHON_PACKAGE_MANAGER}-env || true;
fi
