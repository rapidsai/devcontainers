#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python-wheel [OPTION]...
#
# Build a ${PY_LIB} wheel.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output
#  --ignore-requires-python               Ignore the Requires-Python information.
#  --no-clean                             Don't clean up build directories.
#  --no-deps                              Don't install package dependencies.
#  --no-verify                            Don't verify if built wheel is valid.
#  --no-cache-dir                         Disable the pip cache.
#  --use-pep517                           Use PEP 517 for building source distributions.
#  --no-use-pep517                        Don't use PEP 517 for building source distributions
#  --no-build-isolation                   Disable isolation when building a modern source distribution. Build
#                                         dependencies specified by PEP 518 must be already installed if this option is
#                                         used.
#  --pre                                  Include pre-release and development versions. By default, pip only finds
#                                         stable versions.
#  --prefer-binary                        Prefer binary packages over source packages, even if the source packages are
#                                         newer.
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
#  -D* <var>[:<type>]=<value>             Create or update a cmake cache entry.
#  --cache-dir <dir>                      Store the cache data in <dir>.
#  --only-binary <format_control>         Do not use source packages. Can be supplied multiple times, and each time
#                                         adds to the existing value. Accepts either ":all:" to disable all source
#                                         packages, ":none:" to empty the set, or one or more package names with commas
#                                         between them. Packages without binary distributions will fail to install when
#                                         this option is used on them.
#  -w,--wheel-dir <dir>                   copy built wheel into <dir>
#                                         (default: none)

is_using_scikit_build_core() {
    local -;
    set -euo pipefail;
    test -f "${PY_SRC}/pyproject.toml";
    test "scikit_build_core.build" = "$(python -c "import toml; print(toml.load('${PY_SRC}/pyproject.toml')['build-system']['build-backend'])")";
}

build_${PY_LIB}_python_wheel() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"build-all"*}" \
      || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python"*}" \
      || test -z "${rapids_build_utils_debug##*"build-${PY_LIB}-python-wheel"*}"; }; then
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

    if test -n "${v}"; then
        cmake_args+=("--log-level=VERBOSE");
    fi

    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${v:+--log-level=VERBOSE});
    cmake_args+=("${OPTS[@]}");

    local ninja_args=();
    local pip_args=(${PIP_WHEEL_ARGS});

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

    if test -n "${pre:-}"; then
        pip_args+=("--pre");
    fi

    if test -n "${wheel_dir:-}"; then
        pip_args+=("--wheel-dir" "${wheel_dir}");
    fi

    if test -n "${prefer_binary:-}"; then
        pip_args+=("--prefer-binary");
    fi

    if test -n "${only_binary[@]:-}"; then
        pip_args+=("--only-binary");
        if test "${only_binary[@]}" != "true"; then
            pip_args+=("${only_binary[@]}");
        fi
    fi

    if test -n "${no_deps:-}"; then
        pip_args+=("--no-deps");
    fi

    if test -n "${no_clean:-}"; then
        pip_args+=("--no-clean");
    fi

    if test -n "${no_verify:-}"; then
        pip_args+=("--no-verify");
    fi

    if test -n "${cache_dir:-}"; then
        pip_args+=("--cache-dir" "${cache_dir:-}");
    elif test -n "${no_cache_dir:-}"; then
        pip_args+=("--no-cache-dir");
    fi

    if test -n "${use_pep517:-}"; then
        pip_args+=("--use-pep517");
    elif test -n "${no_use_pep517:-}"; then
        pip_args+=("--no-use-pep517");
    fi

    if test -n "${no_build_isolation:-}"; then
        pip_args+=("--no-build-isolation");
        if is_using_scikit_build_core; then
            local -r bin_dir="$(rapids-get-cmake-build-dir "${PY_SRC}" "${cmake_args[@]}")";
            pip_args+=("--config-settings=build-dir=${bin_dir}");
        fi
    fi

    if test -n "${ignore_requires_python:-}"; then
        pip_args+=("--ignore-requires-python");
    fi

    pip_args+=("${PY_SRC}");

    trap "rm -rf '${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    time (
        export ${PY_ENV} PATH="$PATH";

        local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
        local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

        CUDAFLAGS="${cudaflags}"                 \
        CMAKE_GENERATOR="Ninja"                  \
        PARALLEL_LEVEL="${n_jobs}"               \
        CMAKE_ARGS="${cmake_args[*]}"            \
        SKBUILD_BUILD_OPTIONS="${ninja_args[*]}" \
        NVCC_APPEND_FLAGS="${nvcc_append_flags}" \
            python -m pip wheel ${pip_args[@]}   \
        ;
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} wheel build time:";
    ) 2>&1;
}

build_${PY_LIB}_python_wheel "$@";
