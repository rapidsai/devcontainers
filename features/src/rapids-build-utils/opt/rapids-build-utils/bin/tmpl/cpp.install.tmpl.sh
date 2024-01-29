#!/usr/bin/env bash

# Usage:
#  install-${CPP_LIB}-cpp [OPTION]...
#
# Install ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 Enable verbose output.
#  --strip                      Strip before installing.
#
# Options that require values:
#  -p,--prefix <dir>                            Install C++ library into <dir>
#                                               (default: none)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.

install_${CPP_LIB}_cpp() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"install-all"*}" \
      || test -z "${rapids_build_utils_debug##*"install-${CPP_LIB}-cpp"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        -v,--verbose
        --strip
        --config
        --default-directory-permissions
    ' - <<< "${@@Q}")";

    component=(${component[@]:-all});
    prefix="${p:-${CMAKE_INSTALL_PREFIX:-/usr/local}}";

    local comp;
    for comp in "${component[@]}"; do
        if test "all" = "${comp}"; then
            comp="";
        fi
        time (
            cmake \
                --install "${CPP_SRC}"/build/latest/                 \
                --prefix "${p:-${CMAKE_INSTALL_PREFIX:-/usr/local}}" \
                ${comp:+--component "${comp}"}                       \
                "${OPTS[@]}";
            { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB}${component:+ $component} install time:";
        ) 2>&1;
    done
}

install_${CPP_LIB}_cpp "$@";
