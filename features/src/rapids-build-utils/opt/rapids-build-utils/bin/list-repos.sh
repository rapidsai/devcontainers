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

    if test ${#repo[@]} -gt 0; then
        # prefix each element
        repo=("${repo[@]/#/'.name == "'}");
        # suffix each element
        repo=("${repo[@]/%/'" or'}");
        filters+=("| map(select(${repo[@]} false))");
    fi

    if test ${#omit[@]} -gt 0; then
        # prefix each element
        omit=("${omit[@]/#/'.name != "'}");
        # suffix each element
        omit=("${omit[@]/%/'" and'}");
        filters+=("| map(select(${omit[@]} true))");
    fi

    if test -n "${filters:-}"; then
        query=".repos ${filters[*]} | {repos: .}";
    fi

    rapids-query-manifest "${OPTS[@]}" -- "${query}";
}

list_repos "$@" <&0;
