#!/usr/bin/env bash

# Usage:
#  build-all-python [OPTION]...
#
# Runs build-<repo>-python for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_options /usr/bin/build-${NAME}-python -h | tail -n+2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_build_all_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-all-python';

    for name in ${NAMES}; do
        if command -v build-${name}-python >/dev/null 2>&1; then
            build-${name}-python "${OPTS[@]}";
        fi
    done
}

_build_all_python "$@" <&0;
