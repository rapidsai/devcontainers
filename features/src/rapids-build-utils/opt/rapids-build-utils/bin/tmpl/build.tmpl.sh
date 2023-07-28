#! /usr/bin/env bash

build_${NAME}() {
    set -euo pipefail;
    for lib in ${CPP_LIB}; do
        if type build-${lib}-cpp >/dev/null 2>&1; then
            build-${lib}-cpp "$@";
        fi
    done
    for lib in ${PY_LIB}; do
        if type build-${lib}-python >/dev/null 2>&1; then
            build-${lib}-python "$@";
        fi
    done
}

(build_${NAME} "$@");
