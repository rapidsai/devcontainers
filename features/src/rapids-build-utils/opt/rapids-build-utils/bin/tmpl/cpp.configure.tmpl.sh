#!/usr/bin/env bash

# Usage:
#  configure-${CPP_LIB}-cpp [OPTION]...
#
# Configure ${CPP_LIB}.
#
# Boolean options:
#  -h,--help     Print this text.
#  -v,--verbose  Verbose output.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

configure_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    export ${CPP_ENV} PATH="$PATH";

    eval "$(                                          \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc --all)}  \
        rapids-get-num-archs-jobs-and-load "$@"       \
        2>/dev/null                                   \
    )";

    local -a cmake_args_="(${CMAKE_ARGS:-})";
    cmake_args_+=(${CPP_CMAKE_ARGS});

    eval "$(_parse_args --take '-G, -v,--verbose' "$@" "${cmake_args_[@]}" <&0)";

    if [[ ! -d "${CPP_SRC}" ]]; then
        echo "configure-${CPP_LIB}-cpp: cannot access '${CPP_SRC}': No such directory" >&2;
        exit 1;
    fi

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'configure-all configure-${NAME} configure-${CPP_LIB}-cpp';

    local -a cmake_args="(
        -G\"${G:-Ninja}\"
        ${cmake_args_[*]@Q}
        ${CPP_DEPS}
        ${v:+--log-level=VERBOSE}
        $(rapids-select-cmake-args "$@")
    )";

    # Reconfigure if previous configure failed
    local -r bin_dir="$(rapids-maybe-clean-build-dir "${cmake_args[@]}" --  "${CPP_SRC}")";

    cmake_args+=(-S "${CPP_SRC}");
    cmake_args+=(-B "${bin_dir:-${CPP_SRC}/${BIN_DIR}}");

    time (
        export ${CPP_ENV} PATH="$PATH";

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

    rapids-merge-compile-commands-json > ~/compile_commands.json;
}

configure_${CPP_LIB}_cpp "$@" <&0;
