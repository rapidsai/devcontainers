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
#  --ignore-requires-python               Ignore the Requires-Python information.
#  --no-clean                             Don't clean up build directories.
#  --no-deps                              Don't install package dependencies.
#  --no-verify                            Don't verify if built wheel is valid.
#  --no-cache-dir                         Disable the pip cache.
#  --use-pep517                           Use PEP 517 for building source distributions.
#  --no-use-pep517                        Don't use PEP 517 for building source distributions
#  --no-build-isolation                   Disable isolation when building a modern source distribution. Build
#                                         dependencies specified by PEP 518 must be already installed if this option is
#                                         used.
#  --pre                                  Include pre-release and development versions. By default, pip only finds
#                                         stable versions.
#  --prefer-binary                        Prefer binary packages over source packages, even if the source packages are
#                                         newer.
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
#  -t,--type (editable|wheel)             The type of Python build to run (editable or wheel)
#                                         (default: editable)
#  -D* <var>[:<type>]=<value>             Create or update a cmake cache entry.
#  --cache-dir <dir>                      Store the cache data in <dir>.
#  --only-binary <format_control>         Do not use source packages. Can be supplied multiple times, and each time
#                                         adds to the existing value. Accepts either ":all:" to disable all source
#                                         packages, ":none:" to empty the set, or one or more package names with commas
#                                         between them. Packages without binary distributions will fail to install when
#                                         this option is used on them.
#  -w,--wheel-dir <dir>                   copy built wheel into <dir>
#                                         (default: none)

build_all() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"build-all"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for name in ${NAMES}; do
        if type build-${name} >/dev/null 2>&1; then
            build-${name} "$@";
        fi
    done
}

build_all "$@";
