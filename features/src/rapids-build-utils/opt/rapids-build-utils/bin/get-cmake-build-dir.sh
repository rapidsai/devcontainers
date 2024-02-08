#!/usr/bin/env bash

# Usage:
#  rapids-get-cmake-build-dir <source_path> [cmake_args]...
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
# Positional arguments:
# source_path      The C++ or Python project source path
# [cmake_args]...  The list of CMake arguments to search for the CMAKE_BUILD_TYPE

get_cmake_build_dir() {
    local -;
    set -euo pipefail;

    local src="${1:-}";
    if test $# -gt 0; then shift; fi;

    local bin="build";
    local -r type="$(rapids-parse-cmake-build-type "$@" <&0 | tr '[:upper:]' '[:lower:]')";
    local -r cuda="$(grep -o '^[0-9]*.[0-9]*' <<< "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}")";

    bin+="${PYTHON_PACKAGE_MANAGER:+/${PYTHON_PACKAGE_MANAGER}}${cuda:+/cuda-${cuda}}";

    if test -n "${src:-}" && test -d "${src:-}"; then
        mkdir -p "${src}/${bin}";
        (
            cd "${src}/${bin}" || exit 1;
            ln -sfn "${type}" latest;
        );
    fi
    echo "${src:+${src}/}${bin}/${type}";
}

get_cmake_build_dir "$@" <&0;
