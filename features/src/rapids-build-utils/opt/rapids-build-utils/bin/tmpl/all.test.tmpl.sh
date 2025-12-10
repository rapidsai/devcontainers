#!/usr/bin/env bash

# Usage:
#  test-all [OPTION]...
#
# Runs test-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

test_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'test-all';

    for name in ${NAMES}; do
        if command -V test-${name} >/dev/null 2>&1; then
            test-${name} "${OPTS[@]}";
        fi
    done
}

test_all "$@" <&0;
