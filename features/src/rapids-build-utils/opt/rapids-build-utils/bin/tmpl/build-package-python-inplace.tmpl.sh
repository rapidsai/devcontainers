#! /usr/bin/env bash

build_python_inplace_${PY_LIB}() {

    set -euo pipefail;

    if [[ ! -d ~/${PY_SRC} ]]; then
        exit 1;
    fi

    local verbose="";
    local parallel="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            a|archs                           |
            j|parallel                        |
            v|verbose                         |
            m|max-device-obj-memory-usage     |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";
    parallel="${j:-${parallel:-${JOBS:-${PARALLEL_LEVEL:-$(nproc --ignore=2)}}}}";

    local cmake_args=();

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
    if test -n "${parallel}"; then
        if [ "${parallel:-}" = "true" ]; then
            parallel="";
        fi
        ninja_args+=("-j${parallel}");
    fi

    local pip_args=();
    if test -n "${verbose}"; then
        pip_args+=("-vv");
    fi
    pip_args+=("--no-build-isolation");
    pip_args+=("--no-deps");
    pip_args+=("--editable");
    pip_args+=(~/"${PY_SRC}");
    cmake_args+=("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON");

    trap "rm -rf ~/'${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    time                                         \
    CMAKE_GENERATOR="Ninja"                      \
    CMAKE_ARGS="${cmake_args[@]}"                \
    SKBUILD_BUILD_OPTIONS="${ninja_args[@]}"     \
    SETUPTOOLS_ENABLE_FEATURES="legacy-editable" \
        python -m pip install ${pip_args[@]}     \
    ;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_python_inplace_${PY_LIB} "$@");
