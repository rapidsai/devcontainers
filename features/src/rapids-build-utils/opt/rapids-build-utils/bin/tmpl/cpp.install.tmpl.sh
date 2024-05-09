#!/usr/bin/env bash

# Usage:
#  install-${CPP_LIB}-cpp [OPTION]...
#
# Install ${CPP_LIB}.
#
# @_include_cmake_install_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

install_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '--component --prefix' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all install-${NAME} install-${CPP_LIB}-cpp';

    ((${#component[@]})) || component=(all);

    prefix="$(realpath -ms "${prefix:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}")";

    local comp;
    for comp in "${component[@]}"; do
        if test "all" = "${comp}"; then
            comp="";
        fi
        time (
            local -a cmake_install_args="($(rapids-select-cmake-install-args "${OPTS[@]}"))";
            cmake --install "${CPP_SRC}/${BIN_DIR}/" \
                  --prefix "${prefix}"               \
                  ${comp:+--component "${comp}"}     \
                  "${cmake_install_args[@]}";

            { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB}${component:+ $component} install time:";
        ) 2>&1;
    done
}

install_${CPP_LIB}_cpp "$@" <&0;
