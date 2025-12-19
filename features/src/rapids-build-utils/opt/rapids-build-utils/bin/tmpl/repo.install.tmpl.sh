#!/usr/bin/env bash

# Usage:
#  install-${NAME} [OPTION]...
#
# Install ${CPP_LIB}.
#
# @_include_cmake_install_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

install_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all install-${NAME}';

    for lib in ${CPP_LIB}; do
        if command -V install-${lib}-cpp >/dev/null 2>&1; then
            echo -e "\033[1;36mInstalling ${lib} C++\033[0m";
            install-${lib}-cpp "${OPTS[@]}";
        fi
    done
}

install_${NAME} "$@" <&0;
