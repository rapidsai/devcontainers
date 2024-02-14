#!/usr/bin/env bash

# Usage:
#  rapids-pull-repositories [OPTION]...
#
# Pull the latest commits from each repository's upstream remote.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

pull_repositories() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'pull-repositories';

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

        while [[ -z "$(git -C ~/${!repo_path} branch -r | grep upstream/${branch_name})" ]]; do

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

pull_repositories "$@" <&0;
