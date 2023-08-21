#! /usr/bin/env bash

configure_${CPP_LIB}_cpp() {

    set -euo pipefail;

    if [[ ! -d ~/${CPP_SRC} ]]; then
        exit 1;
    fi

    local parallel="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            j|parallel                        |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    parallel="${j:-${parallel:-}}";

    local build_type="$(rapids-parse-cmake-build-type ${__rest__[@]} | tr '[:upper:]' '[:lower:]')";
    local binary_dir=~/${CPP_SRC}/build/${build_type};
    local source_dir=~/${CPP_SRC};

    # Reconfigure if previous configure failed
    if [[ ! -f ${binary_dir}/build.ninja ]]; then
        rm -rf ${binary_dir};
    fi

    mkdir -p ${binary_dir};
    ln -sfn ${binary_dir} ${source_dir}/build/latest;

    local cmake_args=();
    cmake_args+=(-S ${source_dir});
    cmake_args+=(-B ${binary_dir});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${__rest__[@]});

    eval "$(                                    \
        rapids-get-jobs-and-archs -j${parallel} \
      | xargs -r -d'\n' -I% echo -n local %\;   \
    )";

    time                                                     \
    CUDAFLAGS="${CUDAFLAGS:+$CUDAFLAGS }--threads ${n_arch}" \
    cmake $(rapids-parse-cmake-args ${cmake_args[@]});

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

(configure_${CPP_LIB}_cpp "$@");
