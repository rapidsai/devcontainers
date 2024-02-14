#!/usr/bin/env bash

# Usage:
#  clean-${NAME} [OPTION]...
#
# Clean the ${NAME} repository.
#
# Boolean options:
#  -h,--help          print this text

clean_${NAME}() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-${NAME}';

    for lib in ${CPP_LIB}; do
        if type clean-${lib}-cpp >/dev/null 2>&1; then
            clean-${lib}-cpp "$@";
        fi
    done
    for lib in ${PY_LIB}; do
        if type clean-${lib}-python >/dev/null 2>&1; then
            clean-${lib}-python "$@";
        fi
    done
}

clean_${NAME} "$@";
