#!/usr/bin/env bash

# Usage:
#  rapids-pull-repositories [OPTION]...
#
# Pull the latest commits from each repository's upstream remote.
#
# Boolean options:
#  -h,--help,--usage     print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to only include <repo> entries.
#                        (default: all repositories)

pull_repositories() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"pull-repositories"*}"; }; then
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
        fi;

        echo "Pulling ${!repo_name}..."
        git -C ~/${!repo_path} fetch --no-tags upstream;
        git -C ~/${!repo_path} fetch --no-tags origin;

        local branch_name="$(git -C ~/${!repo_path} rev-parse --abbrev-ref HEAD)";

        while ! git -C ~/${!repo_path} branch -r | grep -q "upstream/${branch_name}"; do

            local upstream_info="$(git -C ~/${!repo_path} remote -v show | grep upstream | head -n1)";

            read -rp "
############################################################
Branch \"$branch_name\" not found in:
${upstream_info}
############################################################

Please enter a branch name to pull (or leave empty to skip): " branch_name </dev/tty
        done;

        if [[ -n "${branch_name}" ]]; then
            git -C ~/${!repo_path} pull --no-tags upstream "${branch_name}";
            git -C ~/${!repo_path} submodule update --init --recursive;
        else
            echo "No alternate branch name supplied, skipping";
        fi;

    done
}

pull_repositories "$@";
