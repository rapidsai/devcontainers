#!/usr/bin/env bash

# Usage:
#  configure-${NAME} [OPTION]...
#
# Runs the configure script in each ${CPP_LIB}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

configure_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'configure-all configure-${NAME}';

    for lib in ${CPP_LIB}; do
        if command -V configure-${lib}-cpp >/dev/null 2>&1; then
            echo -e "\033[1;36mConfiguring ${lib} C++\033[0m";
            configure-${lib}-cpp "${OPTS[@]}";
        fi
    done
}

configure_${NAME} "$@" <&0;
