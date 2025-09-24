#!/usr/bin/env bash

# Usage:
#  rapids-select-cmake-build-type [OPTIONS] [cmake_args]...
#
# Finds the -DCMAKE_BUILD_TYPE=<val> definition from a list of input CMake arguments.
# If -DCMAKE_BUILD_TYPE=<val> is found in <cmake_args>, <val> is printed to stdout.
# Otherwise, nothing is printed and the script exits with an error code.
#
# Boolean options:
#  -h,--help       Print this text.
#
# Positional arguments:
# [cmake_args]...  The list of CMake arguments to search

# shellcheck disable=SC1091
. rapids-generate-docstring;

select_cmake_build_type() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'select-cmake-build-type';

    local build_type="$(rapids-select-cmake-define CMAKE_BUILD_TYPE "${OPTS[@]}" "${REST[@]}")";

    case "${build_type,,}" in
        debug)
            echo "Debug"
            ;;
        minsizerel)
            echo "MinSizeRel"
            ;;
        release)
            echo "Release"
            ;;
        relwithdebinfo)
            echo "RelWithDebInfo"
            ;;
        *)
            return 1;
            ;;
    esac
}

select_cmake_build_type "$@" <&0;
