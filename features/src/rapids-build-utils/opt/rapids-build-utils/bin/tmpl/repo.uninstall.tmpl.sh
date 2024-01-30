#!/usr/bin/env bash

# Usage:
#  uninstall-${NAME} [OPTION]...
#
# Uninstall ${CPP_LIB} and ${PY_LIB}.
#
# Boolean options:
#  -h,--help,--usage  print this text
#  -v,--verbose       verbose output

uninstall_${NAME}() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"uninstall-all"*}" \
      || test -z "${rapids_build_utils_debug##*"uninstall-${NAME}"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for lib in ${CPP_LIB}; do
        if type uninstall-${lib}-cpp >/dev/null 2>&1; then
            uninstall-${lib}-cpp "$@";
        fi
    done

    for lib in ${PY_LIB}; do
        if type uninstall-${lib}-python >/dev/null 2>&1; then
            uninstall-${lib}-python "$@";
        fi
    done
}

uninstall_${NAME} "$@";
