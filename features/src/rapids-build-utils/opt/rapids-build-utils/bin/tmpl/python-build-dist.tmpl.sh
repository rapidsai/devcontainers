#! /usr/bin/env bash

build_${PY_LIB}_python_dist() {

    echo "python dist builds not yet implemented";
    exit 1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${PY_LIB}_python_dist "$@";
