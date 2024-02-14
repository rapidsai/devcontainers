#!/usr/bin/env bash

# Usage:
#  ${SCRIPT}-all [OPTION]...
#
# Runs the ${SCRIPT} in each ${NAMES}.
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                              print this text
#  -v,--verbose                           verbose output

${SCRIPT}_all() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' '${SCRIPT}-all';

    for name in ${NAMES}; do
        if type ${SCRIPT}-${name} >/dev/null 2>&1; then
            ${SCRIPT}-${name} "$@";
        fi
    done
}

${SCRIPT}_all "$@";
