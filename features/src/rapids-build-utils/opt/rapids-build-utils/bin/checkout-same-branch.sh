#!/usr/bin/env bash

# Usage:
#  rapids-checkout-same-branch [OPTION]...
#
# Fetch all branches from the origin and upstream remotes,
# prompts the user to select a branch they all have in common.
# then checks out all repositories to this common branch.
#
# Boolean options:
#  -h,--help,--usage  print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to include <repo> entries.
#                        (default: all repositories)

. devcontainer-utils-parse-args-from-docstring;

checkout_same_branch() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

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

        local remote="${branch_name/\/*}";
        local branch="${branch_name/*\/}";

        git -C ~/${!repo_path} fetch ${remote} "refs/heads/${branch}";

        if ! git -C ~/${!repo_path} checkout -b "${branch}" -t "${remote}/${branch}" 2>/dev/null; then
            git -C ~/${!repo_path} checkout "${branch}";
            git -C ~/${!repo_path} branch "${branch}" -u "${remote}/${branch}";
        fi

        git -C ~/${!repo_path} submodule update --init --recursive -j $(nproc --ignore=2);
    done;
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"checkout-same-branch"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(checkout_same_branch "$@");
