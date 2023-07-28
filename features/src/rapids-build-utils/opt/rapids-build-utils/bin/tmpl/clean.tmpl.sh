#! /usr/bin/env bash

clean_${NAME}() {
    set -euo pipefail;
    for lib in ${CPP_LIB}; do
        if type clean-${lib}-cpp >/dev/null 2>&1; then
            clean-${lib}-cpp "$@";
        fi
    done
    for lib in ${PY_LIB}; do
        if type clean-${lib}-python >/dev/null 2>&1; then
            clean-${lib}-python "$@";
        fi
    done
}

(clean_${NAME} "$@");
