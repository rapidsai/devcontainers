#! /usr/bin/env bash

build_cpp_${NAME}() {
    set -euo pipefail;
    for lib in ${CPP_LIB}; do
        if type build-${lib}-cpp >/dev/null 2>&1; then
            build-${lib}-cpp "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_cpp_${NAME} "$@");
