#! /usr/bin/env bash

clean_${NAME}() {
    set -euo pipefail;
    for lib in ${CPP_LIB}; do
        if [[ -n "$lib" ]]; then "clean-${lib}-cpp"; fi
    done
    for package in ${PY_LIB}; do
        if [[ -n "$package" ]]; then "clean-${package}-python"; fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${NAME} "$@");
