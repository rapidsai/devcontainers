#!/usr/bin/env bash

# Usage:
#  build-${CPP_LIB}-cpp [OPTION]...
#
# Configure and build ${CPP_LIB}.
#
# @_include_options /usr/bin/configure-${CPP_LIB}-cpp -h | tail -n+2;
# @_include_cmake_build_options

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-j,--parallel' "$@" <&0)";

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
    )";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME} build-${CPP_LIB}-cpp';

    if [[ ! -d "${CPP_SRC}" ]]; then
        exit 1;
    fi

    configure-${CPP_LIB}-cpp ${j:+"-j${j}"} "${OPTS[@]}";

    # Build C++ lib
    time (
        local -a cmake_build_args="($(rapids-select-cmake-build-args ${n_jobs:+-j${n_jobs}} "${OPTS[@]}"))";

        cmake                               \
        --build "${CPP_SRC}/${BIN_DIR}"     \
        "${cmake_build_args[@]}"            \
        --                                  \
        ${n_load:+-l${n_load}}              ;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} build time:";
    ) 2>&1;
}

build_${CPP_LIB}_cpp "$@" <&0;
