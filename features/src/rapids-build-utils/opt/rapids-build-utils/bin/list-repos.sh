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

. devcontainer-utils-parse-args-from-docstring;

list_repos() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local repos=();
    repos+=(${r[@]:-}); unset r;
    repos+=(${repo[@]:-}); unset repo;
    repos=(${repos[@]:-});

    local omits=();
    omits+=(${o[@]:-}); unset o;
    omits+=(${omit[@]:-}); unset omit;
    omits=(${omits[@]:-});

    local query=".repos | {repos: .}";
    local filters=();

    if test ${#repos[@]} -gt 0; then
        # prefix each element
        repos=("${repos[@]/#/'.name == "'}");
        # suffix each element
        repos=("${repos[@]/%/'" or'}");
        filters+=("| map(select(${repos[@]} false))");
    fi

    if test ${#omits[@]} -gt 0; then
        # prefix each element
        omits=("${omits[@]/#/'.name != "'}");
        # suffix each element
        omits=("${omits[@]/%/'" and'}");
        filters+=("| map(select(${omits[@]} true))");
    fi

    if test -n "${filters:-}"; then
        query=".repos ${filters[@]} | {repos: .}";
    fi

    rapids-query-manifest "$@" "${query}";
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"list-repos"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(list_repos "$@");
