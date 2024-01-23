#!/usr/bin/env bash

# Usage:
#  build-${CPP_LIB}-cpp [OPTION]...
#
# Configure and build ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
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

. devcontainer-utils-parse-args-from-docstring;

build_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    local verbose="${v:-${verbose:-}}";

    configure-${CPP_LIB}-cpp ${verbose:+-v} ${__rest__[@]};

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
      | xargs -r -d'\n' -I% echo -n local %\;   \
    )";

    # Build C++ lib
    time (
        cmake                               \
        --build "${CPP_SRC}/build/latest"   \
        ${verbose:+--verbose}               \
        -j${n_jobs}                         \
        --                                  \
        -l${n_load}                         ;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} build time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"build-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${CPP_LIB}_cpp "$@";
