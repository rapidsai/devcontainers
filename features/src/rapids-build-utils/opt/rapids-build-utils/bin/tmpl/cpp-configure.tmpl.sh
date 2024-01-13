#! /usr/bin/env bash

configure_${CPP_LIB}_cpp() {

    set -euo pipefail;

    if [[ ! -d ~/"${CPP_SRC}" ]]; then
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

    local build_type="$(rapids-parse-cmake-build-type ${__rest__[@]} | tr '[:upper:]' '[:lower:]')";
    local binary_dir=~/"${CPP_SRC}/build/${build_type}";
    local source_dir=~/"${CPP_SRC}";

    # Reconfigure if previous configure failed
    if [[ ! -f ${binary_dir}/build.ninja ]]; then
        rm -rf ${binary_dir};
    fi

    mkdir -p ${binary_dir};
    ln -sfn ${binary_dir} ${source_dir}/build/latest;

    local cmake_args=(-GNinja);
    cmake_args+=(-S ${source_dir});
    cmake_args+=(-B ${binary_dir});
    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${verbose:+--log-level=VERBOSE});
    cmake_args+=(${__rest__[@]});

    time (
        CUDAFLAGS="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}" \
            cmake ${cmake_args[@]};
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} configure time:";
    ) 2>&1;

    if [[ ! -L ${source_dir}/compile_commands.json \
            || "$(readlink "${source_dir}/compile_commands.json")" \
            != ${source_dir}/build/latest/compile_commands.json ]]; then
        ln -sfn \
            ${source_dir}/build/latest/compile_commands.json \
            ${source_dir}/compile_commands.json \
            ;
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

configure_${CPP_LIB}_cpp "$@";
