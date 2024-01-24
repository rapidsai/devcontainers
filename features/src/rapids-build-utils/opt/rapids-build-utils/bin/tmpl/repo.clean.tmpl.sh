#!/usr/bin/env bash

# Usage:
#  clean-${NAME} [OPTION]...
#
# Clean the ${NAME} repository.
#
# Boolean options:
#  -h,--help,--usage            print this text

. devcontainer-utils-parse-args-from-docstring;

clean_${NAME}() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

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

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"clean-${NAME}"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_${NAME} "$@";
