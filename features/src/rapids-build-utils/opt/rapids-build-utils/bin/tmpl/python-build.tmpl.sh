#! /usr/bin/env bash

build_${PY_LIB}_python() {

    set -euo pipefail;

    if [[ ! -d ~/${PY_SRC} ]]; then
        exit 1;
    fi

    local cmake_args=();

    # Define both lowercase and uppercase
    # `-DFIND_<lib>_CPP=ON` and `-DFIND_<LIB>_CPP=ON` because the RAPIDS
    # scikit-build CMakeLists.txt's aren't 100% consistent in the casing
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${@});

    local ninja_args=();
    ninja_args+=("-v");
    ninja_args+=("-j${JOBS:-${PARALLEL_LEVEL:-$(nproc --ignore=2)}}");

    local pip_args=();
    pip_args+=("-vv");
    pip_args+=("--no-build-isolation");
    pip_args+=("--no-deps");
    pip_args+=("--editable");
    pip_args+=(~/${PY_SRC});
    cmake_args+=("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON");

    trap "rm -rf ~/${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info" EXIT;

    time                                              \
    CMAKE_GENERATOR="Ninja"                           \
    SKBUILD_BUILD_OPTIONS="${ninja_args[@]}"          \
    SETUPTOOLS_ENABLE_FEATURES="legacy-editable"      \
    CMAKE_ARGS="$(rapids-parse-cmake-args ${cmake_args[@]})" \
        python -m pip install ${pip_args[@]}          \
    ;
}

(build_${PY_LIB}_python "$@");
