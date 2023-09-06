#! /usr/bin/env bash

clean_${NAME}() {
    set -euo pipefail;
    clean-${NAME}-cpp "$@";
    clean-${NAME}-python "$@";
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${NAME} "$@");
