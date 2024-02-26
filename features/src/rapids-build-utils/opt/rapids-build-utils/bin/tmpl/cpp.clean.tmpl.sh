#!/usr/bin/env bash

# Usage:
#  clean-${CPP_LIB}-cpp [OPTION]...
#
# Clean the ${CPP_LIB} build dirs.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

clean_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-${NAME} clean-${CPP_LIB}-cpp';

    if [[ ! -d "${CPP_SRC}" ]]; then
        return;
    fi

    rm -rf -- \
        "${CPP_SRC}/${BIN_DIR}"/{*,.*} \
        "${CPP_SRC}"/compile_commands.json \
        2>/dev/null || true;
}

clean_${CPP_LIB}_cpp "$@" <&0;
