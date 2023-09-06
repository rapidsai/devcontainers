#! /usr/bin/env bash

clean_${NAME}_cpp() {
    set -euo pipefail;
    local exe
    for lib in ${CPP_LIB}; do
        exe="clean-${NAME}-cpp-${lib}"
        if type $exe 2>&1; then $exe "$@"; fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${NAME}_cpp "$@");
