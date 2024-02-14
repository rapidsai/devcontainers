#!/usr/bin/env bash

# Usage:
#  uninstall-${NAME} [OPTION]...
#
# Uninstall ${CPP_LIB} and ${PY_LIB}.
#
# Boolean options:
#  -h,--help          Print this text.
#  -v,--verbose       verbose output

# shellcheck disable=SC1091
. rapids-generate-docstring;

uninstall_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all uninstall-${NAME}';

    for lib in ${CPP_LIB}; do
        if type uninstall-${lib}-cpp >/dev/null 2>&1; then
            uninstall-${lib}-cpp "${OPTS[@]}";
        fi
    done

    for lib in ${PY_LIB}; do
        if type uninstall-${lib}-python >/dev/null 2>&1; then
            uninstall-${lib}-python "${OPTS[@]}";
        fi
    done
}

uninstall_${NAME} "$@" <&0;
