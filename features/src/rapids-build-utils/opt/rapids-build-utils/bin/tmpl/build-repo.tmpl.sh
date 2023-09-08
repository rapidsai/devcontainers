#! /usr/bin/env bash

build_${NAME}() {
    set -euo pipefail;
    build-${NAME}-inplace
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME} "$@");
