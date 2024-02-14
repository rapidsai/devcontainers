#!/usr/bin/env bash

# Usage:
#  uninstall-all [OPTION]...
#
# Runs uninstall-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help     Print this text.
#  -v,--verbose  Verbose output.

# shellcheck disable=SC1091
. rapids-generate-docstring;

uninstall_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all';

    for name in ${NAMES}; do
        if type uninstall-${name} >/dev/null 2>&1; then
            uninstall-${name} "${OPTS[@]}";
        fi
    done
}

uninstall_all "$@" <&0;
