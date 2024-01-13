#! /usr/bin/env bash

clean_${CPP_LIB}_cpp() {

    set -euo pipefail;

    rm -rf "${CPP_SRC}/build/latest"/* \
           "${CPP_SRC}"/compile_commands.json;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_${CPP_LIB}_cpp "$@";
