#! /usr/bin/env bash

clean_${CPP_LIB}_cpp() {

    set -euo pipefail;

    rm -rf ~/${PY_SRC}/_skbuild;
    rm -rf ~/${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info;
    find ~/${PY_SRC}/${PY_LIB}/ -type f \
        -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
        -delete;
}

(clean_${CPP_LIB}_cpp "$@");
