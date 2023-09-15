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
        fi

        echo "Pushing ${!repo_name}...";

        git -C ~/${!repo_path} push origin $(git -C ~/${!repo_path} rev-parse --abbrev-ref HEAD);
    done;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(checkout_same_branch "$@");
