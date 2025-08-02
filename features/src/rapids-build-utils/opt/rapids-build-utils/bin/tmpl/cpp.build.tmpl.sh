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

    eval "$(\
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc --all)} \
    MAX_TOTAL_SYSTEM_MEMORY="${MAX_TOTAL_SYSTEM_MEMORY:-${CPP_MAX_TOTAL_SYSTEM_MEMORY}}" \
    MAX_DEVICE_OBJ_MEMORY_USAGE="${MAX_DEVICE_OBJ_MEMORY_USAGE:-${CPP_MAX_DEVICE_OBJ_MEMORY_USAGE}}" \
    MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL="${MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL:-${CPP_MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL}}" \
        rapids-get-num-archs-jobs-and-load "$@" \
        2>/dev/null \
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
        echo "Building lib${CPP_LIB}";
        export ${CPP_ENV} PATH="$PATH";
        local -a cmake_build_args="($(rapids-select-cmake-build-args ${n_jobs:+-j${n_jobs}} "${OPTS[@]}"))";
        cmake                               \
            --build "${CPP_SRC}/${BIN_DIR}" \
            "${cmake_build_args[@]}" 2>&1   ;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} build time:";
    ) 2> >(tee -a /var/log/devcontainer-utils/build-${CPP_LIB}-cpp-time.log >&2);
}

build_${CPP_LIB}_cpp "$@" <&0;
