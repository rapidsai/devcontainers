#!/usr/bin/env bash

# Usage:
#  uninstall-${PY_LIB}-python [OPTION]...
#
# Uninstall ${PY_LIB}.
#
# Boolean options:
#  -h,--help     Print this text.
#  -q,--quiet    Less output. Option is additive, and can be
#                used up to 3 times (corresponding to WARNING,
#                ERROR, and CRITICAL logging levels).
#  -v,--verbose  Give more output. Option is additive, and can be
#                used up to 3 times.

# shellcheck disable=SC1091
. rapids-generate-docstring;

uninstall_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help -q,--quiet -v|--verbose' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all uninstall-${NAME} uninstall-${PY_LIB}-python';

    pip uninstall --no-input -y "${v[@]}" "${q[@]}" "${PY_LIB}" || true;

}

uninstall_${PY_LIB}_python "$@" <&0;
