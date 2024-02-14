#!/usr/bin/env bash

# Usage:
#  build-all [OPTION]...
#
# Runs build-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_options /usr/bin/build-${NAME} -h | tail -n+2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all';

    for name in ${NAMES}; do
        if type build-${name} >/dev/null 2>&1; then
            build-${name} "${OPTS[@]}";
        fi
    done
}

build_all "$@" <&0;
