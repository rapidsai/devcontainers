#! /usr/bin/env bash

configure_${NAME}() {
    set -euo pipefail;
    for lib in ${CPP_LIB}; do
        if type configure-${lib}-cpp >/dev/null 2>&1; then
            configure-${lib}-cpp "$@";
        fi
    done
}

(configure_${NAME} "$@");
