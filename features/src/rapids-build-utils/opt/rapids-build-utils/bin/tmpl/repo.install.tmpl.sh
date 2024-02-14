#!/usr/bin/env bash

# Usage:
#  install-${NAME} [OPTION]...
#
# Install ${CPP_LIB} and ${PY_LIB}.
#
# Boolean options:
#  -h,--help          print this text
#  -v,--verbose       verbose output
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

install_${NAME}() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all install-${NAME}';

    for lib in ${CPP_LIB}; do
        if type install-${lib}-cpp >/dev/null 2>&1; then
            install-${lib}-cpp "$@";
        fi
    done
}

install_${NAME} "$@";
