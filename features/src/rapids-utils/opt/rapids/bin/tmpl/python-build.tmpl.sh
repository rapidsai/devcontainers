#! /usr/bin/env -S bash -euo pipefail

build_${PY_LIB}_python() {

    if [[ ! -d ~/${CPP_LIB}/.git ]]; then
        exit 1;
    fi

    local cpp_bin="$(realpath -m ~/${CPP_SRC}/build/latest)";

    if [[ ! -f ${cpp_bin}/build.ninja ]]; then
        build-${CPP_LIB}-cpp "$@";
    fi

    # Define both lowercase and uppercase
    # `-DFIND_<lib>_CPP=ON` and `-DFIND_<LIB>_CPP=ON` because the RAPIDS
    # scikit-build CMakeLists.txt's aren't 100% consistent in the casing
    local cmake_args=();

    local cpp_lib_lower="$(echo "${CPP_LIB}" | tr '[:upper:]' '[:lower:]')";
    cmake_args+=(-D FIND_${cpp_lib_lower}_CPP=TRUE);
    cmake_args+=(-D ${cpp_lib_lower}_ROOT=${cpp_bin});

    local cpp_lib_upper="$(echo "${CPP_LIB}" | tr '[:lower:]' '[:upper:]')";
    cmake_args+=(-D FIND_${cpp_lib_upper}_CPP=TRUE);
    cmake_args+=(-D ${cpp_lib_upper}_ROOT=${cpp_bin});

    cmake_args+=(${CPP_ARGS});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${@});

    local ninja_args=();
    ninja_args+=("-v");
    ninja_args+=("-j${PARALLEL_LEVEL:-$(nproc --ignore=2)}");

    local pip_args=();
    pip_args+=("-vv");
    pip_args+=("--no-build-isolation");
    pip_args+=("--no-deps");
    pip_args+=("--editable");
    pip_args+=(~/${PY_SRC});

    trap "rm -rf ~/${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info" EXIT;

    CMAKE_GENERATOR="Ninja"                           \
    SKBUILD_BUILD_OPTIONS="${ninja_args[@]}"          \
    SETUPTOOLS_ENABLE_FEATURES="legacy-editable"      \
    CMAKE_ARGS="$(rapids-parse-cmake-args ${cmake_args[@]})" \
        python -m pip install ${pip_args[@]}          \
    ;
}

build_${PY_LIB}_python "$@";
