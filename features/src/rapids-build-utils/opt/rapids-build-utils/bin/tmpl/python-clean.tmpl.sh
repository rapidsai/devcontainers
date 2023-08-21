#! /usr/bin/env bash

clean_${PY_LIB}_cpp() {

    set -euo pipefail;

    local py_lib="$(tr '-' '_' <<< "${PY_LIB}")";

    rm -rf ~/"${PY_SRC}"/{build,_skbuild};
    rm -rf ~/"${PY_SRC}/${py_lib}.egg-info";

    if test -d ~/"${PY_SRC}/${PY_LIB}"/; then
        find ~/"${PY_SRC}/${PY_LIB}"/ -type f \
            -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
            -delete;
    fi

    if test -d ~/"${PY_SRC}/${py_lib}"/; then
        find ~/"${PY_SRC}/${py_lib}"/ -type f \
            -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
            -delete;
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_${PY_LIB}_cpp "$@");
