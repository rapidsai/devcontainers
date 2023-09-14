#! /usr/bin/env bash

configure_${NAME}_cpp() {
    set -euo pipefail;
    local exe
    for lib in ${CPP_LIB}; do
        exe="configure-${lib}-cpp"
        if type $exe >/dev/null 2>&1; then $exe "$@"; fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(configure_${NAME}_cpp "$@");
