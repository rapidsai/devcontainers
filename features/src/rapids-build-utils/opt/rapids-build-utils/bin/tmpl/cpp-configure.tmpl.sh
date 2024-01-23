#!/usr/bin/env bash

# Usage:
#  configure-${CPP_LIB}-cpp [OPTION]...
#
# Configure ${CPP_LIB}.
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

configure_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    local verbose="${v:-${verbose:-}}";

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
      | xargs -r -d'\n' -I% echo -n local %\;   \
    )";

    local build_type="$(rapids-parse-cmake-build-type ${__rest__[@]} | tr '[:upper:]' '[:lower:]')";
    local binary_dir="${CPP_SRC}/build/${build_type}";
    local source_dir="${CPP_SRC}";

    # Reconfigure if previous configure failed
    if [[ ! -f ${binary_dir}/build.ninja ]]; then
        rm -rf ${binary_dir};
    fi

    mkdir -p ${binary_dir};
    ln -sfn ${binary_dir} ${source_dir}/build/latest;

    local cmake_args=(-GNinja);
    cmake_args+=(-S ${source_dir});
    cmake_args+=(-B ${binary_dir});
    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${verbose:+--log-level=VERBOSE});
    cmake_args+=(${__rest__[@]});

    time (
        CUDAFLAGS="${CUDAFLAGS:+$CUDAFLAGS }-t${n_arch}" \
            cmake ${cmake_args[@]};
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} configure time:";
    ) 2>&1;

    if [[ ! -L ${source_dir}/compile_commands.json \
            || "$(readlink "${source_dir}/compile_commands.json")" \
            != ${source_dir}/build/latest/compile_commands.json ]]; then
        ln -sfn \
            ${source_dir}/build/latest/compile_commands.json \
            ${source_dir}/compile_commands.json \
            ;
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"configure-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

configure_${CPP_LIB}_cpp "$@";
