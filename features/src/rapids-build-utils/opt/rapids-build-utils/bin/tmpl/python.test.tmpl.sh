#!/usr/bin/env bash

# Usage:
#  test-${PY_LIB}-python [OPTION]...
#
# Run ${PY_LIB} Python tests.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

test_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'test-all test-${NAME} test-${PY_LIB}-python';

    if [[ ! -d "${SRC_PATH}" ]]; then
        echo "test-${PY_LIB}-python: cannot access '${SRC_PATH}': No such directory" >&2;
        return 1;
    fi

    time (
        cd "${SRC_PATH}";
        ./${PY_TEST} "${OPTS[@]}";
    )
}

test_${PY_LIB}_python "$@" <&0;
