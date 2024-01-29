#!/usr/bin/env bash

# Usage:
#  rapids-list-repos [OPTION]...
#
# Query the `manifest.yaml` in a shell-friendly format, optionally filtering results by repository name.
#
# Boolean options:
#  -h,--help,--usage     print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to include <repo> entries.
#                        (default: all repositories)

list_repos() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        -m,--manifest
    ' - <<< "${@@Q}")";

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

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
    || test -z "${rapids_build_utils_debug##*"list-repos"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

list_repos "$@";
