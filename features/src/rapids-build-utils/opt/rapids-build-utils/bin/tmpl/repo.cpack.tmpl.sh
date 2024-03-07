#!/usr/bin/env bash

# Usage:
#  cpack-${NAME} [OPTION]...
#
# CPack ${CPP_LIB}.
#
# Boolean options:
#  -h,--help                                     Print this text.
# @_include_bool_options rapids-select-cmake-install-args -h | tail -n-3 | head -n-1;
#
# Options that require values:
#  -j,--parallel <num>                           Use <num> threads to compress in parallel.
#                                                (default: $(nproc))
#  -o,--out-dir <dir>                            Copy cpack'd TGZ file into <dir>.
#                                                (default: none)
# @_include_value_options rapids-select-cmake-install-args -h | tail -n-5 | head -n-2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

cpack_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'cpack-all cpack-${NAME}';

    for lib in ${CPP_LIB}; do
        if type cpack-${lib}-cpp >/dev/null 2>&1; then
            cpack-${lib}-cpp "${OPTS[@]}";
        fi
    done
}

cpack_${NAME} "$@" <&0;
