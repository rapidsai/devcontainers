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
#  -t,--type editable|wheel               The type of Python build to run (editable or wheel)
#                                         (default: editable)

. devcontainer-utils-parse-args-from-docstring;

build_${PY_LIB}_python() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    build-${PY_LIB}-python-${t:-${type:-"editable"}} ${__rest__[@]};
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${PY_LIB}_python "$@";
