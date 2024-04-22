#!/usr/bin/env bash

# Usage:
#  install-${PY_LIB}-python [OPTION]...
#
# Install ${PY_LIB}.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;
# @_include_pip_install_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

install_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(                                          \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc --all)}  \
        rapids-get-num-archs-jobs-and-load "$@"       \
        2>/dev/null                                   \
    )";

    local py_lib="${PY_LIB}";

    local -a cmake_args_="(${CMAKE_ARGS:-})";
    cmake_args_+=(${CPP_CMAKE_ARGS});

    local -a pip_args_=(${PIP_INSTALL_ARGS});

    eval "$(_parse_args --take '-G -e,--editable -v,--verbose' "$@" "${cmake_args_[@]}" "${pip_args_[@]}" <&0)";

    if [[ ! -d "${PY_SRC}" ]]; then
        echo "install-${PY_LIB}-python: cannot access '${PY_SRC}': No such directory" >&2;
        exit 1;
    fi

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME} build-${PY_LIB}-python build-${PY_LIB}-python-editable install-all install-${NAME} install-${PY_LIB}-python';

    local -a cmake_args="(
        -G \"${G:-Ninja}\"
        ${cmake_args_[*]@Q}
        ${CPP_DEPS}
        ${v:+--log-level=VERBOSE}
        $(rapids-select-cmake-args "$@")
    )";

    if test -n "${v-}"; then
        ninja_args+=("-v");
    fi

    if test -n "${n_jobs-}"; then
        ninja_args+=("-j${n_jobs}");
    fi

    if test -n "${n_load-}"; then
        ninja_args+=("-l${n_load}");
    fi

    local -a pip_args="(
        ${pip_args_+"${pip_args_[*]@Q}"}
        $(rapids-select-pip-install-args "$@")
    )";

    if rapids-python-uses-scikit-build "${PY_SRC}"; then
        # Clean the `_skbuild/.../cmake-build` dir if configuration failed before
        if ! test -d "$(rapids-maybe-clean-build-dir "${cmake_args[@]}" -- "${PY_SRC}")"; then
            rm -rf "${PY_SRC}/_skbuild";
        fi
        if test ${#editable[@]} -gt 0; then
            export SETUPTOOLS_ENABLE_FEATURES=legacy-editable;
        fi
    elif rapids-python-uses-scikit-build-core "${PY_SRC}"; then
        pip_args+=(-C "build-dir=$(rapids-maybe-clean-build-dir "${cmake_args[@]}" -- "${PY_SRC}")");
    fi

    # Put --editable at the end of pip_args
    if test ${#editable[@]} -gt 0; then
        cmake_args+=("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON");
        local i;
        local n=1;
        test -n "${editable:-}" && n=2;
        for ((i=0; i < ${#pip_args}; i+=1)); do
            case "${pip_args[${i}]}" in
                -e|--editable)
                    pip_args=("${pip_args[@]:0:$i}" "${pip_args[@]:$((i + n))}");
                    break;
                    ;;
            esac
        done
        pip_args+=(--editable "${editable:-${PY_SRC}}");
    else
        pip_args+=("${PY_SRC}");
    fi

    trap "rm -rf '${PY_SRC}/${py_lib//"-"/"_"}.egg-info'" EXIT;

    time (
        export ${PY_ENV} PATH="$PATH";

        local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
        local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

        CUDAFLAGS="${cudaflags}"                     \
        CMAKE_GENERATOR="${G:-Ninja}"                \
        PARALLEL_LEVEL="${n_jobs}"                   \
        CMAKE_ARGS="${cmake_args[*]}"                \
        SKBUILD_BUILD_OPTIONS="${ninja_args[*]}"     \
        NVCC_APPEND_FLAGS="${nvcc_append_flags}"     \
            python -m pip install "${pip_args[@]}"   \
        ;
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} install time:";
    ) 2>&1;
}

install_${PY_LIB}_python "$@" <&0;
