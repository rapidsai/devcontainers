#! /usr/bin/env bash

clean_${PY_LIB}_cpp() {

    set -euo pipefail;

    local py_lib="$(tr '-' '_' <<< "${PY_LIB}")";

    rm -rf ~/"${PY_SRC}"/{_skbuild,${py_lib}.egg-info};

    local python_version="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";
    python_version="${python_version/./}";

    local dir;
    for dir in lib temp dist; do
        local slug="${dir}.$(uname -s)-$(uname -m)-cpython-${python_version/./}";
        if test -d ~/"${PY_SRC}"/build/${slug,,}; then
            rm -rf ~/"${PY_SRC}"/build/${slug,,};
        fi
    done

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
