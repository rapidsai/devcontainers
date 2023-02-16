#! /usr/bin/env -S bash -euo pipefail

configure_${CPP_LIB}_cpp() {

    if [[ ! -d ~/${CPP_LIB}/.git ]]; then
        exit 1;
    fi

    local build_type="$(rapids-parse-cmake-build-type "$@" | tr '[:upper:]' '[:lower:]')";
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
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${@});

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

configure_${CPP_LIB}_cpp "$@";
