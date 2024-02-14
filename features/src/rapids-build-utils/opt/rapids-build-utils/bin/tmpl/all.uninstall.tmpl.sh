#!/usr/bin/env bash

# Usage:
#  uninstall-all [OPTION]...
#
# Runs uninstall-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output

uninstall_all() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all';

    for name in ${NAMES}; do
        if type uninstall-${name} >/dev/null 2>&1; then
            uninstall-${name} "$@";
        fi
    done
}

uninstall_all "$@";
