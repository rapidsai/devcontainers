#!/usr/bin/env bash

# Usage:
#  install-${CPP_LIB}-cpp [OPTION]...
#
# Install ${CPP_LIB}.
#
# Boolean options:
#  -h,--help                    print this text
#  -v,--verbose                 Enable verbose output.
#  --strip                      Strip before installing.
#
# Options that require values:
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.
#  -p,--prefix <dir>                            Install C++ library into <dir>
#                                               (default: none)

install_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -v,--verbose
        --strip
        --config
        --default-directory-permissions
    ' - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all install-${NAME} install-${CPP_LIB}-cpp';

    test ${#component[@]} -eq 0 && component=(all);
    prefix="${p:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}";

    local comp;
    for comp in "${component[@]}"; do
        if test "all" = "${comp}"; then
            comp="";
        fi
        time (
            cmake \
                --install "${CPP_SRC}/${BIN_DIR}/"                              \
                --prefix "${p:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}" \
                ${comp:+--component "${comp}"}                                  \
                "${OPTS[@]}";
            { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB}${component:+ $component} install time:";
        ) 2>&1;
    done
}

install_${CPP_LIB}_cpp "$@";
