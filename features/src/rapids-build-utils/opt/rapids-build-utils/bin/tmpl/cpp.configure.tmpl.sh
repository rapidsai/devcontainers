#!/usr/bin/env bash

# Usage:
#  configure-${CPP_LIB}-cpp [OPTION]...
#
# Configure ${CPP_LIB}.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

configure_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
    )";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'configure-all configure-${NAME} configure-${CPP_LIB}-cpp';

    local -a cmake_args_=(
        -GNinja
        ${CMAKE_ARGS:-}
        ${CPP_DEPS}
        ${CPP_ARGS}
        ${v:+--log-level=VERBOSE}
    );
    local -a cmake_args="(
        ${cmake_args_+"${cmake_args_[*]@Q}"}
        $(rapids-select-cmake-args "${ARGS[@]}")
    )";

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

configure_${CPP_LIB}_cpp "$@" <&0;
