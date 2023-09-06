#! /usr/bin/env bash

clean_${NAME}_python() {
    set -euo pipefail;
    local exe
    for lib in ${PY_LIB}; do
        exe="clean-${NAME}-python-${lib}"
        if type $exe 2>&1; then $exe "$@"; fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${NAME}_python "$@");
