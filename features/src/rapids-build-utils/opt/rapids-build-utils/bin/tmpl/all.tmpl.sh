#!/usr/bin/env bash

# Usage:
#  ${SCRIPT}-all [OPTION]...
#
# Runs the ${SCRIPT} in each ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help     Print this text.
#  -v,--verbose  Verbose output.

# shellcheck disable=SC1091
. rapids-generate-docstring;

${SCRIPT}_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' '${SCRIPT}-all';

    for name in ${NAMES}; do
        if type ${SCRIPT}-${name} >/dev/null 2>&1; then
            ${SCRIPT}-${name} "${OPTS[@]}";
        fi
    done
}

${SCRIPT}_all "$@" <&0;
