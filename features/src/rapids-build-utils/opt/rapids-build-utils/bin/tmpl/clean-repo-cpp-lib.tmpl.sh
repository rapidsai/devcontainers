#! /usr/bin/env bash

clean_${NAME}_cpp_${CPP_LIB}() {
    set -euo pipefail;
    rm -rf ~/${CPP_SRC}/build/latest/*;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${NAME}_cpp_${CPP_LIB} "$@");
