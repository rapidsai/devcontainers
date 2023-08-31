#!/usr/bin/env bash

checkout_same_branch() {
    set -euo pipefail;

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

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

        local branch_name=$(git -C ~/${!repo_path} rev-parse --abbrev-ref HEAD);

        while [[ -z "$(git -C ~/${!repo_path} branch -r | grep upstream/$branch_name)" ]]; do

            local upstream_info="$(git -C ~/${!repo_path} remote -v show | grep upstream | head -n1)";

            read -p "
############################################################
Branch \"$branch_name\" not found in:
${upstream_info}
############################################################

Please enter a branch name to pull (or leave empty to skip): " branch_name </dev/tty
        done;

        if [[ -n "$branch_name" ]]; then
            git -C ~/${!repo_path} pull --no-tags upstream "$branch_name";
            git -C ~/${!repo_path} submodule update --init --recursive;
        else
            echo "No alternate branch name supplied, skipping";
        fi;

    done;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(checkout_same_branch "$@");
