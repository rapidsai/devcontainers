#! /usr/bin/env bash

build_${NAME}_inplace_cpp() {
    set -euo pipefail;
    local exe
    for lib in ${CPP_LIB}; do
        exe="build-${lib}-cpp"
        if type $exe 2>&1; then $exe "$@"; fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_inplace_cpp "$@");
