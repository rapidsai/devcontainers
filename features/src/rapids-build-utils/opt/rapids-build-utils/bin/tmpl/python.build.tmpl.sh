#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python [OPTION]...
#
# Build an editable install or wheel of ${PY_LIB}.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output
#
# Options that require values:
#  -t,--type (editable|wheel)             The type of Python build to run (editable or wheel)
#                                         (default: editable)

build_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"build-all"*}" \
      || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    build-${PY_LIB}-python-${t:-${type:-"editable"}} "${OPTS[@]}";
}

build_${PY_LIB}_python "$@";
