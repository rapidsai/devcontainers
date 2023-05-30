#! /usr/bin/env bash

clean_${NAME}() {
    set -euo pipefail;
    if type clean-${NAME}-cpp >/dev/null 2>&1; then
        clean-${NAME}-cpp;
    fi
    if type clean-${NAME}-python >/dev/null 2>&1; then
        clean-${NAME}-python;
    fi
}

(clean_${NAME} "$@");
