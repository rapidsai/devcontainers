#!/usr/bin/env bash

# Usage:
#  rapids-get-cmake-build-dir [OPTIONS] [--] <source_path> [cmake_args]...
#
# Build a path to the build directory for a C++ or scikit-build-core Python library.
# If the <source_path> is not null and a valid directory, retarget the `build/(pip|conda)/cuda-X.Y.Z/latest` symlink
# to point to the fully resolved build dir path.
#
# The build dir path includes components for:
# * PYTHON_PACKAGE_MANAGER envvar (if set)
# * CUDA Toolkit version (if set)
# * the CMake build type
#
# This allows users to persist C++ and Python builds per [package manager] x [CUDA Toolkit] x [build type] combination,
# meaning they don't need to do a clean build if switching between devcontainers or build types.
#
# Boolean options:
#  -h,--help          Print this text.
#  --skip-build-type  Don't update the symlink pointing to the last component of
#                     the build dir path, i.e. "latest -> (debug|release)".
#
# Positional arguments:
# source_path      The C++ or Python project source path
# [cmake_args]...  The list of CMake arguments to search for the CMAKE_BUILD_TYPE

# shellcheck disable=SC1091
. rapids-generate-docstring;

get_cmake_build_dir() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'get-cmake-build-dir';

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi;

    local bin="build";
    local src="${REST[0]:-}";
    local -r type="$(rapids-select-cmake-build-type "${OPTS[@]}" "${REST[@]:1}" | tr '[:upper:]' '[:lower:]')";
    local -r cuda="$(grep -o '^[0-9]*.[0-9]*' <<< "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}")";

    bin+="${PYTHON_PACKAGE_MANAGER:+/${PYTHON_PACKAGE_MANAGER}}${cuda:+/cuda-${cuda}}";

    if test -n "${src:-}" && test -d "${src:-}"; then
        mkdir -p "${src}/${bin}";
        if test -z "${skip_build_type-}"; then
            mkdir -p "${src}/${bin}/${type}";
            cd "${src}/${bin}/" || exit 1;
            ln -sfn "${type}" latest;
        fi
        cd "${src}/build" || exit 1;
        local component;
        for component in "${PYTHON_PACKAGE_MANAGER:-}" "${cuda:+cuda-${cuda}}"; do
            if test -n "${component:-}"; then
                ln -sfn "${component}/latest" latest;
                cd "${component}" || exit 1;
            fi
        done
    fi
    if test -n "${skip_build_type-}"; then
        echo "${src:+${src}/}${bin}/latest";
    else
        echo "${src:+${src}/}${bin}/${type}";
    fi
    # echo "$(realpath -m "${src:+${src}/}${bin}/${type}")";
}

get_cmake_build_dir "$@" <&0;
