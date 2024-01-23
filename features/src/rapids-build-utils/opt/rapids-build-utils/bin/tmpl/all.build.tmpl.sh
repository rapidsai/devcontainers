#!/usr/bin/env bash

# Usage:
#  build-all [OPTION]...
#
# Runs build-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output
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
#  -t,--type editable|wheel               The type of Python build to run (editable or wheel)
#                                         (default: editable)
#  -D* <var>[:<type>]=<value>             Create or update a cmake cache entry.

. devcontainer-utils-parse-args-from-docstring;

build_all() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    for name in ${NAMES}; do
        if type build-${name} >/dev/null 2>&1; then
            build-${name} "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"build-all"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_all "$@";
