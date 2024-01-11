#! /usr/bin/env bash

build_${PY_LIB}_python_wheel() {

    set -euo pipefail;

    if [[ ! -d ~/"${PY_SRC}" ]]; then
        exit 1;
    fi

    local archs="";
    local parallel="";
    local max_device_obj_memory_usage="";

    local verbose="";
    local wheel_dir="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            a|archs                           |
            j|parallel                        |
            m|max-device-obj-memory-usage     |
            v|verbose                         |
            w|wheel-dir                       |
            prefer-binary                     |
            only-binary                       |
            no-deps                           |
            no-clean                          |
            no-verify                         |
            no-cache-dir                      |
            no-use-pep517                     |
            no-build-isolation                |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";
    wheel_dir="${w:-${wheel_dir:-}}";

    archs="${a:-${archs:-}}";
    parallel="${j:-${parallel:-}}";
    max_device_obj_memory_usage="${m:-${max_device_obj_memory_usage:-}}";

    eval "$(                                                                    \
        rapids-get-num-archs-jobs-and-load                                      \
            ${archs:+-a ${archs}}                                               \
            ${parallel:+-j ${parallel}}                                         \
            ${max_device_obj_memory_usage:+-m ${max_device_obj_memory_usage}}   \
      | xargs -r -d'\n' -I% echo -n local %\;                                   \
    )";

    local cmake_args=(${PY_CMAKE_ARGS});

    if test -n "${verbose}"; then
        cmake_args+=("--log-level=VERBOSE");
    fi

    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${__rest__[@]});

    local ninja_args=();

    if test -n "${verbose}"; then
        ninja_args+=("-v");
    fi

    if test -n "${n_jobs}"; then
        ninja_args+=("-j${n_jobs}");
    fi

    if test -n "${n_load}"; then
        ninja_args+=("-l${n_load}");
    fi

    local pip_args=(${PIP_WHEEL_ARGS});

    if test -n "${verbose}"; then
        pip_args+=("-vv");
    fi

    if test -n "${wheel_dir:-}"; then
        pip_args+=("-w" "${wheel_dir}");
    fi

    if test -n "${prefer_binary:-}"; then
        pip_args+=("--prefer-binary");
        if [ "${prefer_binary:-}" != "true" ]; then
            pip_args+=("${prefer_binary:-}");
        fi
    fi

    if test -n "${only_binary:-}"; then
        pip_args+=("--only-binary");
        if [ "${only_binary:-}" != "true" ]; then
            pip_args+=("${only_binary:-}");
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

    if test -n "${no_cache_dir:-}"; then
        pip_args+=("--no-cache-dir");
    fi

    if test -n "${no_use_pep517:-}"; then
        pip_args+=("--no-use-pep517");
    fi

    if test -n "${no_build_isolation:-}"; then
        pip_args+=("--no-build-isolation");
    fi

    pip_args+=(~/"${PY_SRC}");

    trap "rm -rf ~/'${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
    local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

    time                                     \
    CUDAFLAGS="${cudaflags}"                 \
    CMAKE_GENERATOR="Ninja"                  \
    PARALLEL_LEVEL="${n_jobs}"               \
    CMAKE_ARGS="${cmake_args[@]}"            \
    SKBUILD_BUILD_OPTIONS="${ninja_args[@]}" \
    NVCC_APPEND_FLAGS="${nvcc_append_flags}" \
        python -m pip wheel ${pip_args[@]}   \
    ;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${PY_LIB}_python_wheel "$@";
