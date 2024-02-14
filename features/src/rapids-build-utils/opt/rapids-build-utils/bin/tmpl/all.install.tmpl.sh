#!/usr/bin/env bash

# Usage:
#  install-all [OPTION]...
#
# Runs install-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output
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

install_all() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'install-all';

    for name in ${NAMES}; do
        if type install-${name} >/dev/null 2>&1; then
            install-${name} "$@";
        fi
    done
}

install_all "$@";
