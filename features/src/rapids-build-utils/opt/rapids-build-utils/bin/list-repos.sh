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
#  -r,--repo <repo>      Filter the results to only include <repo> entries.
#                        (default: all repositories)

. devcontainer-utils-parse-args-from-docstring;

list_repos() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local repos=();
    repos+=(${r[@]:-}); unset r;
    repos+=(${repo[@]:-}); unset repo;
    repos=(${repos[@]:-});

    local query=".repos | {repos: .}";

    if test ${#repos[@]} -gt 0; then
        # prefix each element
        repos=("${repos[@]/#/'.name == "'}");
        # suffix each element
        repos=("${repos[@]/%/'" or'}");
        query="$(cat <<________EOF | tr -s '[:space:]'
        .repos
        | map(select(${repos[@]} false))
        | {repos: .}
________EOF
)";
    fi

    rapids-query-manifest "$@" "${query}";
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"list-repos"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(list_repos "$@");
