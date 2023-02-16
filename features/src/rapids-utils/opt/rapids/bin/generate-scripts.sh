#! /usr/bin/env -S bash -euo pipefail

generate_script() {
    local bin="${1:-}";
    if [ -z "$bin" ]; then exit 1; fi

    cat - \
      | envsubst '$NAME $CPP_LIB $CPP_SRC $CPP_ARGS $CPP_DEPS $PY_SRC $PY_LIB' \
      | sudo tee "/opt/rapids/bin/${bin}.sh" >/dev/null;

    sudo update-alternatives --install \
        "/usr/bin/${bin}" "${bin}" "/opt/rapids/bin/${bin}.sh" 0 \
        >/dev/null 2>&1;
}

generate_scripts() {
    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${1:-}";
    local src="${2:-}";
    local deps="${3:-}";
    local args="${4:-}";

    if [[ ! -d ~/"${lib}/.git" ]]; then
        exit 0;
    fi

    cat ./tmpl/cpp-build.tmpl.sh        \
      | NAME="${lib}"                   \
        CPP_LIB="${lib}"                \
        CPP_SRC="${lib}${src:+/$src}"   \
        CPP_ARGS="${args}"              \
        CPP_DEPS="${deps}"              \
      generate_script "build-${lib}-cpp";

    cat ./tmpl/cpp-configure.tmpl.sh        \
      | NAME="${lib}"                       \
        CPP_LIB="${lib}"                    \
        CPP_SRC="${lib}${src:+/$src}"       \
        CPP_ARGS="${args}"                  \
        CPP_DEPS="${deps}"                  \
      generate_script "configure-${lib}-cpp";

    local py_libs=($(rapids-python-pkg-names $lib));
    local py_dirs=($(rapids-python-pkg-roots $lib));

    for i in "${!py_libs[@]}"; do
        local py_dir="${py_dirs[$i]}";
        local py_lib="${py_libs[$i]}";
        cat ./tmpl/python-build.tmpl.sh           \
          | NAME="${lib}"                         \
            CPP_LIB="${lib}"                      \
            CPP_SRC="${lib}${src:+/$src}"         \
            CPP_ARGS="${args}"                    \
            CPP_DEPS="${deps}"                    \
            PY_SRC="${py_dir}"                    \
            PY_LIB="${py_lib}"                    \
          generate_script "build-${py_lib}-python";
    done

    sudo find /opt/rapids \
        \( -type d -exec chmod 0775 {} \; \
        -o -type f -exec chmod 0755 {} \; \);
}

generate_scripts "$@";
