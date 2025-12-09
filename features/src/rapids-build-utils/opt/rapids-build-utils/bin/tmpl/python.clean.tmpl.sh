#!/usr/bin/env bash

# Usage:
#  clean-${PY_LIB}-python [OPTION]...
#
# Clean the ${PY_LIB} build dirs.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

clean_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-${NAME} clean-${PY_LIB}-python';

    if [[ ! -d "${PY_SRC}" ]]; then
        return;
    fi

    local py_lib="${PY_LIB}";

    rm -rf -- \
        "${PY_SRC}"/_skbuild \
        "${PY_SRC}/${BIN_DIR}"/{*,.*} \
        "${PY_SRC}"/{${py_lib},${py_lib//"-"/"_"}}.egg-info \
        2>/dev/null || true;

    for lib in "${py_lib}" "${py_lib//"-"/"_"}"; do
        if test -d "${PY_SRC}/${lib}/"; then
            find "${PY_SRC}/${lib}/" -type f \
                -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
                -delete;
        fi
    done

    local py_ver="${PYTHON_VERSION:-$("${ORIG_PYTHON:-python3}" --version 2>&1 | cut -d' ' -f2)}";
    py_ver="$(grep -Po '^[0-9]+\.[0-9]+' <<< "${py_ver}")";

    if test -d "${PY_SRC}/build"; then
        local slug="$(uname -s)-$(uname -m)";
        rm -rf --                                                                                   \
            `# scikit-buld-core build dirs`                                                         \
            "${PY_SRC}"/build/cp{${py_ver},${py_ver/./}}-cp{${py_ver},${py_ver/./}}*                \
            `# setuptools/distutils build dirs`                                                     \
            "${PY_SRC}"/build/{lib,temp,dist,bdist}.${slug,,}                                       \
            "${PY_SRC}"/build/{lib,temp,dist,bdist}.${slug,,}-{,cpython}{,-}{${py_ver},${py_ver/./}};
    fi

    python -m pip uninstall --yes "${py_lib}" || true;
}

clean_${PY_LIB}_python "$@" <&0;
