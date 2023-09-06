#! /usr/bin/env bash

build_${NAME}_inplace() {
    set -euo pipefail;
    build-${NAME}-inplace-cpp;
    build-${NAME}-inplace-python;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_inplace "$@");
