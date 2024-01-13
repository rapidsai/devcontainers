#! /usr/bin/env bash

install_${CPP_LIB}_cpp() {

    set -Eeuo pipefail;

    time (
        cmake --install "${CPP_SRC}"/build/latest/ "$@";
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} install time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_${CPP_LIB}_cpp "$@";
