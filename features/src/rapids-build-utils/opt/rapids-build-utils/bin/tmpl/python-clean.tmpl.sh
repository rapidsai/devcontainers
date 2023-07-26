#! /usr/bin/env bash

clean_${CPP_LIB}_cpp() {

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

(clean_${CPP_LIB}_cpp "$@");
