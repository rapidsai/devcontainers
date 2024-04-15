#!/usr/bin/env bash

# Usage:
#  rapids-select-cmd-args <CMD> [OPTION]...
#
# Filter an arguments list to the subset that <CMD> accepts.
#
# Positional arguments:
# CMD   The command for which to filter arguments.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_select_args() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'select-cmd-args';

    local cmd="${1:?missing required positional argument CMD}"; shift;

    eval "$(_parse_args_for_file <(
        devcontainer_utils_debug="" rapids_build_utils_debug="" \
        "${cmd}" -h 2>&1 | sed 's/^/# /'
    ) "$@" <&0)";

    echo "${ARGS[*]}";
}

if ((${#BASH_SOURCE[@]})) && [ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}" ]; then
    _select_args "$@" <&0;
fi
