#!/usr/bin/env bash

# Usage:
#  install-all [OPTION]...
#
# Runs install-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_cmake_install_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

install_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all';

    for name in ${NAMES}; do
        if command -V install-${name} >/dev/null 2>&1; then
            install-${name} "${OPTS[@]}";
        fi
    done
}

install_all "$@" <&0;
