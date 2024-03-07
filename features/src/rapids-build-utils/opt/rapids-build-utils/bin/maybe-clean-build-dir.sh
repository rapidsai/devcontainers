#!/usr/bin/env bash

# Usage:
#  rapids-maybe-clean-build-dir [OPTION]... [--] SRC_DIR
#
# Returns the path to the build directory for <SRC_DIR>.
#
# Optionally cleans the build directory if the configure step for the CMake generator failed.
#
# Boolean options:
#  -h,--help                  Print this text.
#
# Options that require values:
#  -G (Ninja|Unix Makefiles)  The build system generator.

# shellcheck disable=SC1091
. rapids-generate-docstring;

maybe_clean_build_dir() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'maybe-clean-build-dir';

    eval "$(_parse_args "$@" <&0)";

    local -r bin_dir="$(rapids-get-cmake-build-dir "${OPTS[@]}" "${REST[@]}")";

    case "${G:-Ninja}" in
        "Unix Makefiles")
            test -f "${bin_dir}/Makefile" || rm -rf "${bin_dir}";;
        "Ninja")
            test -f "${bin_dir}/build.ninja" || rm -rf "${bin_dir}";;
    esac
    echo "${bin_dir}";
}


maybe_clean_build_dir "$@" <&0;
