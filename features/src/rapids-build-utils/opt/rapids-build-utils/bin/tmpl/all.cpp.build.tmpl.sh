#!/usr/bin/env bash

# Usage:
#  build-all-cpp [OPTION]...
#
# Runs build-<repo>-cpp for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_options /usr/bin/build-${NAME}-cpp -h | tail -n+2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_build_all_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-all-cpp';

    for name in ${NAMES}; do
        if command -V build-${name}-cpp >/dev/null 2>&1; then
            build-${name}-cpp "${OPTS[@]}";
        fi
    done
}

_build_all_cpp "$@" <&0;
