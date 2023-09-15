#!/usr/bin/env bash

checkout_same_branch() {
    set -euo pipefail;

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    echo "Determining available branches...";

    local all_repos=();
    local common_branches="";

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi;

        echo "Fetching ${!repo_name} branches...";
        local remote_branches="$(                           \
            tr '[:space:]' '\0' <<< 'origin upstream'       \
          | xargs -r -0 -P2 -I% sh -c "                     \
              git -C ~/${!repo_path} ls-remote -h %         \
            | cut -f2 | grep -Ev 'refs/heads/pull-request/' \
            | sed 's@refs/heads@%@'"                        \
        )";

        if [ ${#all_repos[@]} -eq 0 ]; then
            # start with first repo's set of branches
            common_branches="$(echo -e "$remote_branches" | sort -V)";
        else
            # get a sorted set of branches common to all repos up to this point
            common_branches="$(echo -e "$common_branches\n$remote_branches" | sort -V | uniq -d)";
        fi

        common_branches="$(echo -e "$common_branches" | grep -v master | grep -v main | sort -Vr)";

        all_repos+=(${!repo_name});

    done;

    if [[ -z $common_branches ]]; then
        echo "No branches in common for repos: ${all_repos[@]}"
        exit 0;
    fi;

    echo "Found branches in common for: ${all_repos[@]}"

    echo "Please select a branch to check out:"

    local branches=(${common_branches});
    local branch_name=""

    select branch_name in "${branches[@]}" "Quit"; do
        if [[ $REPLY -lt $(( ${#branches[@]}+1 )) ]]; then
            break;
        elif [[ $REPLY -eq $(( ${#branches[@]}+1 )) ]]; then
            exit 0;
        else
            echo "Invalid option, please select a branch (or quit)"
        fi
    done;

    echo "Starting checkout."

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_path="${repo}_path";

        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi

        if test -z "${branch_name##*"origin/"*}"; then
            if ! git -C ~/${!repo_path} checkout --recurse-submodules -t "${branch_name}" -b "${branch_name/#origin\//}"   2>/dev/null; then
                git -C ~/${!repo_path} checkout --recurse-submodules "${branch_name/#origin\//}";
                git -C ~/${!repo_path} branch "${branch_name/#origin\//}" -u "${branch_name}";
            fi
        elif test -z "${branch_name##*"upstream/"*}"; then
            if ! git -C ~/${!repo_path} checkout --recurse-submodules -t "${branch_name}" -b "${branch_name/#upstream\//}" 2>/dev/null; then
                git -C ~/${!repo_path} checkout --recurse-submodules "${branch_name/#upstream\//}";
                git -C ~/${!repo_path} branch "${branch_name/#upstream\//}" -u "${branch_name}";
            fi
        fi

        git -C ~/${!repo_path} submodule update --init --recursive;

    done;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(checkout_same_branch "$@");
