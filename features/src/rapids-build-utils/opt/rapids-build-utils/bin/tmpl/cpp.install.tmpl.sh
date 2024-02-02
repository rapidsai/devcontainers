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

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"install-all"*}" \
      || test -z "${rapids_build_utils_debug##*"install-${CPP_LIB}-cpp"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -v,--verbose
        --strip
        --config
        --default-directory-permissions
    ' - <<< "${@@Q}")";

    test ${#component[@]} -eq 0 && component=(all);
    prefix="${p:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}";

    local comp;
    for comp in "${component[@]}"; do
        if test "all" = "${comp}"; then
            comp="";
        fi
        time (
            cmake \
                --install "${CPP_SRC}"/build/latest/                            \
                --prefix "${p:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}" \
                ${comp:+--component "${comp}"}                                  \
                "${OPTS[@]}";
            { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB}${component:+ $component} install time:";
        ) 2>&1;
    done
}

install_${CPP_LIB}_cpp "$@";
