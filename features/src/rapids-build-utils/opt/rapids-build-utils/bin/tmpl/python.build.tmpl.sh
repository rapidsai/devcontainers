#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python [OPTION]...
#
# Build an editable install or wheel of ${PY_LIB}.
#
# Options that require values:
#  -t,--type (editable|wheel)             The type of Python build to run (editable or wheel)
#                                         (default: editable)
# @_include_value_options rapids-get-num-archs-jobs-and-load -h | tail -n+2;
# @_include_cmake_options;
# If `--type=editable`:
#
# @_include_pip_install_options | tr '\n' '\0' | xargs -0 -r -I% echo "  %";
# If `--type=wheel`:
#
# @_include_pip_wheel_options | tr '\n' '\0' | xargs -0 -r -I% echo "  %";
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-t,--type' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME} build-${PY_LIB}-python';

    build-${PY_LIB}-python-${t:-${type:-"editable"}} "${OPTS[@]}";
}

build_${PY_LIB}_python "$@" <&0;
