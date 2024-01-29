#!/usr/bin/env bash

# Usage:
#  clean-${CPP_LIB}-cpp [OPTION]...
#
# Clean the ${CPP_LIB} build dirs.
#
# Boolean options:
#  -h,--help,--usage  print this text

clean_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    rm -rf "${CPP_SRC}/build/latest"/* \
           "${CPP_SRC}"/compile_commands.json;
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"clean-all"*}" \
  || test -z "${rapids_build_utils_debug##*"clean-${CPP_LIB}-cpp"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_${CPP_LIB}_cpp "$@";
