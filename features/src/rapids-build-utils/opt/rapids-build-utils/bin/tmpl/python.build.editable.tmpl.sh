#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python-editable [OPTION]...
#
# Build ${PY_LIB} in editable mode.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;
# @_include_pip_install_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${PY_LIB}_python_editable() {
    install-${PY_LIB}-python --no-build-isolation --no-deps --editable "${PY_SRC}" "$@" <&0;
}

build_${PY_LIB}_python_editable "$@" <&0;
