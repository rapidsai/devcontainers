#!/usr/bin/env bash

# Usage:
#  rapids-select-cmake-define <name> [cmake_args]...
#
# Finds the -D<name>=<val> definition from a list of input CMake arguments.
# If -D<name>=<val> is found in <cmake_args>, <val> is printed to stdout.
# Otherwise, nothing is printed and the script exits with an error code.
#
# Positional arguments:
# name             The name of the CMake define to find
# [cmake_args]...  The list of CMake arguments to search

parse_cmake_define() {
    local -;
    set -euo pipefail;

    local arg;
    local val;
    local def="$1"; shift;

    eval "$(devcontainer-utils-parse-args <(echo -e "\n# -D <def>\n# --D <def>") "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'select-cmake-define';

    for arg in "${D[@]}"; do
        if test "${def}" = "${arg%=*}"; then
            val="${arg#*=}";
        fi
    done
    test -n "${val:+x}" && echo "${val}";
}

parse_cmake_define "$@" <&0;
