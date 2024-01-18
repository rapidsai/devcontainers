#!/usr/bin/env bash

# Usage:
#  clean-${CPP_LIB}-cpp [OPTION]...
#
# Clean the ${CPP_LIB} build dirs.
#
# Boolean options:
#  -h,--help,--usage            print this text

. devcontainer-utils-parse-args-from-docstring;

clean_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    rm -rf "${CPP_SRC}/build/latest"/* \
           "${CPP_SRC}"/compile_commands.json;
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"clean-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_${CPP_LIB}_cpp "$@";
