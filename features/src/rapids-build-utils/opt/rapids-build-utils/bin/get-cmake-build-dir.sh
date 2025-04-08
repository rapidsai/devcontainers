#!/usr/bin/env bash

# Usage:
#  rapids-get-cmake-build-dir [OPTIONS] [-DCMAKE_BUILD_TYPE=(Release|Debug)] [--] <source_path>...
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
#  -h,--help                           Print this text.
#  --skip-links                        Don't update any symlinks
#  --skip-build-type                   Don't update the symlink pointing to the last component of
#                                      the build dir path, i.e. "latest -> (debug|release)".
#
# Positional arguments:
# source_path                          The C++ or Python project source path

# shellcheck disable=SC1091
. rapids-generate-docstring;

get_cmake_build_dir() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'get-cmake-build-dir';

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi

    local src="${REST[0]:-}";

    if test -n "${src:+x}" && rapids-python-uses-scikit-build "${src}"; then
        echo "${src:+${src}/}$(python -c 'from skbuild import constants; print(constants.CMAKE_BUILD_DIR())')";
    else
        local -r type="$(rapids-select-cmake-build-type "${OPTS[@]}" "${REST[@]:1}" | tr '[:upper:]' '[:lower:]')";
        local -r cuda="${CUDA_VERSION_MAJOR_MINOR:-}";
        local bin="build";
        bin+="${PYTHON_PACKAGE_MANAGER:+/${PYTHON_PACKAGE_MANAGER}}${cuda:+/cuda-${cuda}}";

        if test -n "${src:+x}" && test -d "${src:-}"; then
            mkdir -p "${src}/${bin}";
            if  ! test -n "${skip_links:+x}"; then
                if ! test -n "${skip_build_type:+x}" || ! test -L "${src}/${bin}/latest"; then
                    mkdir -p "${src}/${bin}/${type}";
                    cd "${src}/${bin}/" || exit 1;
                    ln -sfn "${type}" latest;
                fi
                cd "${src}/build" || exit 1;
                local component;
                for component in "${PYTHON_PACKAGE_MANAGER:-}" "${cuda:+cuda-${cuda}}"; do
                    if test -n "${component:+x}"; then
                        ln -sfn "${component}/latest" latest;
                        cd "${component}" || exit 1;
                    fi
                done
            fi
        fi

        if test -n "${skip_build_type:+x}"; then
            echo "${src:+${src}/}${bin}/latest";
        else
            echo "${src:+${src}/}${bin}/${type}";
        fi
    fi
}

get_cmake_build_dir "$@" <&0;
