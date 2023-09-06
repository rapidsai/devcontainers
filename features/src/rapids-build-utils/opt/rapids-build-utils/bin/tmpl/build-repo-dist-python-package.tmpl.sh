#! /usr/bin/env bash

build_${NAME}_dist_python_${PY_LIB}() {

    set -euo pipefail;

    if [[ ! -d ~/${PY_SRC} ]]; then
        exit 1;
    fi

    local verbose="";
    local parallel="";
    local wheel_dir="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            a|archs                           |
            j|parallel                        |
            v|verbose                         |
            m|max-device-obj-memory-usage     |
            w|wheel-dir                       |
            prefer-binary                     |
            only-binary                       |
            no-verify                         |
            no-build-isolation                |
            no-deps                           |
            no-use-pep517                     |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";
    wheel_dir="${w:-${wheel_dir:-}}";
    parallel="${j:-${parallel:-${JOBS:-${PARALLEL_LEVEL:-$(nproc --ignore=2)}}}}";

    local cmake_args=();

    if test -n "${verbose}"; then
        cmake_args+=("--log-level=VERBOSE");
    fi

    cmake_args+=(${CMAKE_ARGS:-});
    cmake_args+=(${CPP_DEPS});
    cmake_args+=(${CPP_ARGS});
    # cmake_args+=(${__rest__[@]});

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

    if test -n "${no_build_isolation:-}"; then
        pip_args+=("--no-build-isolation");
    fi

    if test -n "${no_deps:-}"; then
        pip_args+=("--no-deps");
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

    if test -n "${no_verify:-}"; then
        pip_args+=("--no-verify");
    fi

    if test -n "${no_use_pep517:-}"; then
        pip_args+=("--no-use-pep517");
    fi

    pip_args+=(~/"${PY_SRC}");

    trap "rm -rf ~/'${PY_SRC}/$(echo "${PY_LIB}" | tr '-' '_').egg-info'" EXIT;

    time                                     \
    CMAKE_GENERATOR="Ninja"                  \
    CMAKE_ARGS="${cmake_args[@]}"            \
    SKBUILD_BUILD_OPTIONS="${ninja_args[@]}" \
        python -m pip wheel ${pip_args[@]}   \
    ;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_dist_python_${PY_LIB} "$@");
