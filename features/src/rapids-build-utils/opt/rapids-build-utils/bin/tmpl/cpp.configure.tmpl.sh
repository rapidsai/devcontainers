#!/usr/bin/env bash

# Usage:
#  configure-${CPP_LIB}-cpp [OPTION]...
#
# Configure ${CPP_LIB}.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output
#
# Options that require values:
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

configure_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
    )";

    local cmake_args=(-GNinja);
    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=("${v:+--log-level=VERBOSE}");
    cmake_args+=("${OPTS[@]}");
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'configure-all configure-${NAME} configure-${CPP_LIB}-cpp';

    local -r bin_dir="$(rapids-get-cmake-build-dir "${CPP_SRC}" "${cmake_args[@]}")";

    # Reconfigure if previous configure failed
    if [[ ! -f "${bin_dir}/build.ninja" ]]; then
        rm -rf "${bin_dir}";
    fi

    cmake_args+=(-S "${CPP_SRC}");
    cmake_args+=(-B "${bin_dir}");

    time (
        CUDAFLAGS="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}" \
            cmake "${cmake_args[@]}";
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} configure time:";
    ) 2>&1;

    if [[ ! -L "${CPP_SRC}/compile_commands.json" \
            || "$(readlink "${CPP_SRC}/compile_commands.json")" \
            != "${CPP_SRC}/${BIN_DIR}/compile_commands.json" ]]; then
        ln -sfn \
            "${CPP_SRC}/${BIN_DIR}/compile_commands.json" \
            "${CPP_SRC}/compile_commands.json" \
            ;
    fi
}

configure_${CPP_LIB}_cpp "$@";
