#!/usr/bin/env bash

# Usage:
#  uninstall-${NAME} [OPTION]...
#
# Uninstall ${CPP_LIB} and ${PY_LIB}.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output

. devcontainer-utils-parse-args-from-docstring;

uninstall_${NAME}() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    for lib in ${CPP_LIB}; do
        if type uninstall-${lib}-cpp >/dev/null 2>&1; then
            uninstall-${lib}-cpp ${__rest__[@]};
        fi
    done

    for lib in ${PY_LIB}; do
        if type uninstall-${lib}-python >/dev/null 2>&1; then
            uninstall-${lib}-python --type ${t:-${type:-"editable"}} ${__rest__[@]};
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-${NAME}"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

uninstall_${NAME} "$@";
