#!/usr/bin/env bash

# Usage:
#  clean-${PY_LIB}-python [OPTION]...
#
# Clean the ${PY_LIB} build dirs.
#
# Boolean options:
#  -h,--help,--usage            print this text

. devcontainer-utils-parse-args-from-docstring;

clean_${PY_LIB}_python() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    if [[ ! -d "${PY_SRC}" ]]; then
        exit 1;
    fi

    local py_lib="${PY_LIB}";

    rm -rf "${PY_SRC}"/_skbuild \
        "${PY_SRC}"/{${py_lib},${py_lib//"-"/"_"}}.egg-info;

    for lib in ${py_lib} ${py_lib//"-"/"_"}; do
        if test -d "${PY_SRC}"/${lib}/; then
            find "${PY_SRC}"/${lib}/ -type f \
                -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
                -delete;
        fi
    done

    local py_ver="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    py_ver="$(grep -o '^[0-9]*.[0-9]*' <<< "${py_ver}")";

    if test -d "${PY_SRC}"/build; then
        local slug="$(uname -s)-$(uname -m)";
        rm -rf                                                                                      \
            `# scikit-buld-core build dirs`                                                         \
            "${PY_SRC}"/build/cp{${py_ver},${py_ver/./}}-cp{${py_ver},${py_ver/./}}*                \
            `# setuptools/distutils build dirs`                                                     \
            "${PY_SRC}"/build/{lib,temp,dist,bdist}.${slug,,}                                       \
            "${PY_SRC}"/build/{lib,temp,dist,bdist}.${slug,,}-{,cpython}{,-}{${py_ver},${py_ver/./}};
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"clean-${PY_LIB}-python"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_${PY_LIB}_python "$@";