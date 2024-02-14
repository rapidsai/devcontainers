#!/usr/bin/env bash

# Usage:
#  configure-all [OPTION]...
#
# Runs configure-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

configure_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'configure-all';

    for name in ${NAMES}; do
        if type configure-${name} >/dev/null 2>&1; then
            configure-${name} "${OPTS[@]}";
        fi
    done
}

configure_all "$@" <&0;
