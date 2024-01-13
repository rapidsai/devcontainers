#! /usr/bin/env bash

build_${PY_LIB}_python_inplace() {

    set -euo pipefail;

    if [[ ! -d ~/"${PY_SRC}" ]]; then
        exit 1;
    fi

    local archs="";
    local parallel="";
    local max_device_obj_memory_usage="";

    local verbose="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            a|archs                           |
            j|parallel                        |
            m|max-device-obj-memory-usage     |
            v|verbose                         |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";
    config_settings="${C:-${config_settings:-}}";

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

    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${verbose:+--log-level=VERBOSE});
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

    local pip_args=(${PIP_INSTALL_ARGS});

    if test -n "${verbose}"; then
        pip_args+=("-vv");
    fi

    pip_args+=("--no-build-isolation");
    pip_args+=("--no-deps");
    pip_args+=("--editable");
    pip_args+=(~/"${PY_SRC}");

    cmake_args+=("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON");

    trap "rm -rf ~/'${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    time (
        export ${PY_ENV} PATH="$PATH";

        local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
        local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

        CUDAFLAGS="${cudaflags}"                     \
        CMAKE_GENERATOR="Ninja"                      \
        CMAKE_ARGS="${cmake_args[@]}"                \
        SKBUILD_BUILD_OPTIONS="${ninja_args[@]}"     \
        NVCC_APPEND_FLAGS="${nvcc_append_flags}"     \
        SETUPTOOLS_ENABLE_FEATURES="legacy-editable" \
            python -m pip install ${pip_args[@]}     \
        ;
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} install time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${PY_LIB}_python_inplace "$@";
