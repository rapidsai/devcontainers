#!/usr/bin/env bash

# Usage:
#  configure-${NAME} [OPTION]...
#
# Runs the configure script in each ${CPP_LIB}.
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                    print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -a,--archs <num>                       Build <num> CUDA archs in parallel
#                                         (default: 1)
#  -j,--parallel <num>                    Run <num> parallel compilation jobs
#  -m,--max-device-obj-memory-usage <num> An upper-bound on the amount of memory each CUDA device object compilation
#                                         is expected to take. This is used to estimate the number of parallel device
#                                         object compilations that can be launched without hitting the system memory
#                                         limit.
#                                         Higher values yield fewer parallel CUDA device object compilations.
#                                         (default: 1)
#  -D* <var>[:<type>]=<value>             Create or update a cmake cache entry.

configure_${NAME}() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"configure-all"*}" \
      || test -z "${rapids_build_utils_debug##*"configure-${NAME}"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for lib in ${CPP_LIB}; do
        if type configure-${lib}-cpp >/dev/null 2>&1; then
            configure-${lib}-cpp "$@";
        fi
    done
}

configure_${NAME} "$@";
