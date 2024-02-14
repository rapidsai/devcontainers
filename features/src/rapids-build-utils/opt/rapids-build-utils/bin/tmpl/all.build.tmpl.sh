#!/usr/bin/env bash

# Usage:
#  build-all [OPTION]...
#
# Runs build-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output
#
# Options that require values:
#  -t,--type (editable|wheel)             The type of Python build to run (editable or wheel)
#                                         (default: editable)
#  -a,--archs <num>                       Build <num> CUDA archs in parallel
#                                         (default: 1)
#  -j,--parallel <num>                    Run <num> parallel compilation jobs
#                                         (default: $(nproc))
#  -m,--max-device-obj-memory-usage <num> An upper-bound on the amount of memory each CUDA device object compilation
#                                         is expected to take. This is used to estimate the number of parallel device
#                                         object compilations that can be launched without hitting the system memory
#                                         limit.
#                                         Higher values yield fewer parallel CUDA device object compilations.
#                                         (default: 1)
#  -D* <var>[:<type>]=<value>             Create or update a cmake cache entry.

build_all() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all';

    for name in ${NAMES}; do
        if type build-${name} >/dev/null 2>&1; then
            build-${name} "$@";
        fi
    done
}

build_all "$@";
