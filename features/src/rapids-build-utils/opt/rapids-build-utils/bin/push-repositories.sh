#!/usr/bin/env bash

# Usage:
#  rapids-push-repositories [OPTION]...
#
# Push the latest commits from each repository to the origin remote.
#
# Boolean options:
#  -h,--help             print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to only include <repo> entries.
#                        (default: all repositories)

push_repositories() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"push-repositories"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    eval "$(rapids-list-repos "$@")";

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi

        echo "Pushing ${!repo_name}...";

        git -C ~/${!repo_path} push origin "$(git -C ~/${!repo_path} rev-parse --abbrev-ref HEAD)";
    done;
}

push_repositories "$@";
