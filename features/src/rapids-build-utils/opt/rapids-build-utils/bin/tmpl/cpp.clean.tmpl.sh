#!/usr/bin/env bash

# Usage:
#  clean-${CPP_LIB}-cpp [OPTION]...
#
# Clean the ${CPP_LIB} build dirs.
#
# Boolean options:
#  -h,--help          print this text

clean_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-${NAME} clean-${CPP_LIB}-cpp';

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    rm -rf -- \
        "${CPP_SRC}/${BIN_DIR}"/{*,.*} \
        "${CPP_SRC}"/compile_commands.json \
        2>/dev/null || true;
}

clean_${CPP_LIB}_cpp "$@";
