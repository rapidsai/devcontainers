#!/usr/bin/env bash

# Usage:
#  test-${NAME} [OPTION]...
#
# Run ${NAME} tests.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

test_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'test-all test-${NAME}';

    for lib in ${CPP_LIB}; do
        if command -V test-${lib}-cpp >/dev/null 2>&1; then
            echo -e "\033[1;36mRunning ${lib} C++ tests\033[0m";
            test-${lib}-cpp "${OPTS[@]}";
        fi
    done

    for lib in ${PY_LIB}; do
        if command -V test-${lib}-python >/dev/null 2>&1; then
            echo -e "\033[1;36mRunning ${lib} Python tests\033[0m";
            test-${lib}-python "${OPTS[@]}";
        fi
    done
}

test_${NAME} "$@" <&0;
