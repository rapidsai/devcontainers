#!/usr/bin/env bash

# Usage:
#  test-all-cpp [OPTION]...
#
# Runs test-<repo>-cpp for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_test_all_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'test-all test-all-cpp';

    for name in ${NAMES}; do
        if command -V test-${name}-cpp >/dev/null 2>&1; then
            test-${name}-cpp "${OPTS[@]}";
        fi
    done
}

_test_all_cpp "$@" <&0;
