#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-github-user-scopes [OPTION]...
#
# Report the GitHub user's active and/or desired scopes.
#
# Boolean options:
#  -h,--help                    Print this text.
#  -c,--complement              Only print needed scopes that are not active.
#
# Options that require values:
#  -s,--scopes <scope>          Additional authentication scopes the user should have.
#                               Can be specified multiple times.

_github_user_scopes() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'github github-user-scopes';

    local -a active="($(GITHUB_TOKEN=""       \
        gh api -i -X GET --silent rate_limit  \
        2>/dev/null                           \
      | grep -i 'x-oauth-scopes:'             \
      | cut -d' ' -f1 --complement            \
      | tr -d ','                             \
      | tr '\r' '\n'                          \
      | tr '\n' ' '                           \
      | tr -s '[:blank:]'                     \
    ))"

    local -a wanted="($(                            \
      comm -23                                      \
        <(IFS=$'\n'; echo "${scopes[*]}" | sort -s) \
        <(IFS=$'\n'; echo "${active[*]}" | sort -s) \
    ))";

    if ! test -n "${complement:+x}"; then
        wanted=("${active[@]}" "${wanted[@]}");
    fi

    echo "${wanted[*]}";
}

_github_user_scopes "$@" <&0;
