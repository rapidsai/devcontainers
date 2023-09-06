#! /usr/bin/env bash

build_${NAME}_dist() {
    set -euo pipefail;
    build-${NAME}-dist-cpp;
    build-${NAME}-dist-python;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_dist "$@");
