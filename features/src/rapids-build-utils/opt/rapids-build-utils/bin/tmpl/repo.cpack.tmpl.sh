#!/usr/bin/env bash

# Usage:
#  cpack-${NAME} [OPTION]...
#
# CPack ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -o,--out-dir <dir>           copy cpack'd TGZ file into <dir>
#                               (default: none)

cpack_${NAME}() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for lib in ${CPP_LIB}; do
        if type cpack-${lib}-cpp >/dev/null 2>&1; then
            cpack-${lib}-cpp "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"cpack-all"*}" \
  || test -z "${rapids_build_utils_debug##*"cpack-${NAME}"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

cpack_${NAME} "$@";