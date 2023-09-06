#! /usr/bin/env bash

build_${NAME}_inplace_cpp_${CPP_LIB}() {

    set -euo pipefail;
    echo "C++ dist builds not yet implemented"
    exit 1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_inplace_cpp_${CPP_LIB} "$@");
