#!/usr/bin/env bash

# Usage:
#  rapids-list-repos [OPTION]...
#
# Query the `manifest.yaml` in a shell-friendly format, optionally filtering results by repository name.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-query-manifest -h | tail -n+2 | head -n-1;
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to include <repo> entries.
#                        (default: all repositories)

# shellcheck disable=SC1091
. rapids-generate-docstring;

list_repos() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --skip '-m,--manifest' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'list-repos';

    local query=".repos | {repos: .}";
    local filters=();

    local -a include="(${INCLUDE_REPOS:-} ${repo[@]})";
    local -a exclude="(${EXCLUDE_REPOS:-} ${omit[@]})";
    # Remove repos from "include" if they're in "exclude"
    local -a include="($(                           \
      comm -23                                      \
        <(IFS=$'\n'; echo "${include[*]}" | sort -s) \
        <(IFS=$'\n'; echo "${exclude[*]}" | sort -s) \
    ))";

    if test ${#include[@]} -gt 0; then
        # prefix each element
        include=("${include[@]/#/'.name == "'}");
        # suffix each element
        include=("${include[@]/%/'" or'}");
        filters+=("| map(select(${include[@]} false))");
    fi

    if test ${#exclude[@]} -gt 0; then
        # prefix each element
        exclude=("${exclude[@]/#/'.name != "'}");
        # suffix each element
        exclude=("${exclude[@]/%/'" and'}");
        filters+=("| map(select(${exclude[@]} true))");
    fi

    if test -n "${filters:+x}"; then
        query=".repos ${filters[*]} | {repos: .}";
    fi

    rapids-query-manifest "${OPTS[@]}" -- "${query}";
}

list_repos "$@" <&0;
