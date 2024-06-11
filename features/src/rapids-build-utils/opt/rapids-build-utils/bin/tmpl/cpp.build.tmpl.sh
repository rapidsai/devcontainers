#!/usr/bin/env bash

# Usage:
#  build-${CPP_LIB}-cpp [OPTION]...
#
# Configure and build ${CPP_LIB}.
#
# @_include_bool_options /usr/bin/configure-${CPP_LIB}-cpp -h;
# @_include_value_options /usr/bin/configure-${CPP_LIB}-cpp -h;
# @_include_cmake_options;
# @_include_cmake_build_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${CPP_LIB}_cpp() {
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

    eval "$(_parse_args --take '-G -j,--parallel' "$@" "${cmake_args_[@]}" <&0)";

    if [[ ! -d "${CPP_SRC}" ]]; then
        echo "build-${CPP_LIB}-cpp: cannot access '${CPP_SRC}': No such directory" >&2;
        exit 1;
    fi

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME} build-${CPP_LIB}-cpp';

    # Reconfigure if not configured or previous configure failed
    local -r bin_dir="$(rapids-maybe-clean-build-dir -G"${G:-Ninja}" "$@" -- "${CPP_SRC}")";
    test -e "${bin_dir:-${CPP_SRC}/${BIN_DIR}}" || configure-${CPP_LIB}-cpp "$@" <&0;

    # Build C++ lib
    time (
        export ${CPP_ENV} PATH="$PATH";
        local -a cmake_build_args="($(rapids-select-cmake-build-args ${n_jobs:+-j${n_jobs}} "${OPTS[@]}"))";
        cmake                               \
            --build "${CPP_SRC}/${BIN_DIR}" \
            "${cmake_build_args[@]}"        \
            --                              \
            ${n_load:+-l${n_load}}          ;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} build time:";
    ) 2>&1;
}

build_${CPP_LIB}_cpp "$@" <&0;
