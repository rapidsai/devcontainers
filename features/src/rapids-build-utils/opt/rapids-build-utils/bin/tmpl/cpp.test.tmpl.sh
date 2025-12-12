#!/usr/bin/env bash

# Usage:
#  test-${CPP_LIB}-cpp [OPTION]...
#
# Run ${CPP_LIB} C++ tests.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

test_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'test-all test-${NAME} test-${CPP_LIB}-cpp';

    echo -e "\033[1;36mRunning ${CPP_LIB} C++ tests\033[0m";

    if [[ ! -d "${SRC_PATH}" ]]; then
        echo "test-${CPP_LIB}-cpp: cannot access '${SRC_PATH}': No such directory" >&2;
        return 1;
    fi

    time (
        cd "${SRC_PATH}";
        ./${CPP_TEST} "${OPTS[@]}";
    )
}

test_${CPP_LIB}_cpp "$@" <&0;
