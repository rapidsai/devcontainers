#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python-editable [OPTION]...
#
# Build ${PY_LIB} in editable mode.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output
#
# Options that require values:
#  -a,--archs <num>                       Build <num> CUDA archs in parallel
#                                         (default: 1)
#  -j,--parallel <num>                    Run <num> parallel compilation jobs
#                                         (default: $(nproc))
#  -m,--max-device-obj-memory-usage <num> An upper-bound on the amount of memory each CUDA device object compilation
#                                         is expected to take. This is used to estimate the number of parallel device
#                                         object compilations that can be launched without hitting the system memory
#                                         limit.
#                                         Higher values yield fewer parallel CUDA device object compilations.
#                                         (default: 1)

build_${PY_LIB}_python_editable() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"build-all"*}" \
      || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python"*}" \
      || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python-editable"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if [[ ! -d "${PY_SRC}" ]]; then
        exit 1;
    fi

    eval "$(                                    \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}  \
        rapids-get-num-archs-jobs-and-load "$@" \
    )";

    local cmake_args=(${PY_CMAKE_ARGS});

    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${v:+--log-level=VERBOSE});
    cmake_args+=("${OPTS[@]}");

    local ninja_args=();
    local pip_args=(${PIP_INSTALL_ARGS});

    if test -n "${v}"; then
        ninja_args+=("-v");
        pip_args+=("-vv");
    fi

    if test -n "${n_jobs}"; then
        ninja_args+=("-j${n_jobs}");
    fi

    if test -n "${n_load}"; then
        ninja_args+=("-l${n_load}");
    fi

    pip_args+=("--no-build-isolation");
    pip_args+=("--no-deps");
    pip_args+=("--editable");
    pip_args+=("${PY_SRC}");

    cmake_args+=("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON");

    trap "rm -rf '${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    time (
        export ${PY_ENV} PATH="$PATH";

        local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
        local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

        CUDAFLAGS="${cudaflags}"                     \
        CMAKE_GENERATOR="Ninja"                      \
        PARALLEL_LEVEL="${n_jobs}"                   \
        CMAKE_ARGS="${cmake_args[@]}"                \
        SKBUILD_BUILD_OPTIONS="${ninja_args[@]}"     \
        NVCC_APPEND_FLAGS="${nvcc_append_flags}"     \
        SETUPTOOLS_ENABLE_FEATURES="legacy-editable" \
            python -m pip install ${pip_args[@]}     \
        ;
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} install time:";
    ) 2>&1;
}

build_${PY_LIB}_python_editable "$@";
