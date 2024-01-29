#!/usr/bin/env bash

# Usage:
#  clean-${CPP_LIB}-cpp [OPTION]...
#
# Clean the ${CPP_LIB} build dirs.
#
# Boolean options:
#  -h,--help,--usage  print this text

clean_${CPP_LIB}_cpp() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"clean-all"*}" \
      || test -z "${rapids_build_utils_debug##*"clean-${CPP_LIB}-cpp"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    rm -rf "${CPP_SRC}/build/latest"/* \
           "${CPP_SRC}"/compile_commands.json;
}

clean_${CPP_LIB}_cpp "$@";
