#!/usr/bin/env bash

# Usage:
#  build-${NAME} [OPTION]...
#
# Configure and build ${CPP_LIB}, then build an editable install or wheel of ${PY_LIB}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;
# @_include_cmake_install_options;
# @_include_pip_wheel_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-t,--type' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME}';

    for lib in ${CPP_LIB}; do
        if command -v build-${lib}-cpp >/dev/null 2>&1; then
            build-${lib}-cpp "${OPTS[@]}";
        fi
    done

    for lib in ${PY_LIB}; do
        if command -v build-${lib}-python >/dev/null 2>&1; then
            build-${lib}-python-${t:-${type:-"editable"}} "${OPTS[@]}";
        fi
    done
}

build_${NAME} "$@" <&0;
