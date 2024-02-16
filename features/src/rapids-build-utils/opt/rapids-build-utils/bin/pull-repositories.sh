#!/usr/bin/env bash

# Usage:
#  rapids-pull-repositories [OPTION]...
#
# Pull the latest commits from each repository's upstream remote.
#
# Boolean options:
#  -h,--help                    Print this text.
#
# Options that require values:
#  --remote            <remote>  The name of the remote from which to pull.
#                                (default: upstream)
#  -b,--default-branch <branch>  The name of the branch to use if the current branch isn't found in <remote>.
#                                (default: none)
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

    : "${remote:="upstream"}";
    : "${default_branch:=""}";

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi;

        echo "Fetching ${!repo_name} ${remote} branches...";

        git -C ~/${!repo_path} fetch --no-tags "${remote}";

        local branch="$(git -C ~/${!repo_path} rev-parse --abbrev-ref HEAD)";

        while true; do
            if test -n "${branch:-}" \
            && git -C ~/${!repo_path} branch -r | grep "${remote}/${branch}"; then
                break;
            fi
            if test -n "${default_branch:-}" \
            && git -C ~/${!repo_path} branch -r | grep "${remote}/${default_branch}"; then
                branch="${default_branch}";
                break;
            fi

            local remote_info="$(git -C ~/${!repo_path} remote -v show | grep "${remote}" | head -n1)";

            read -rp "
############################################################
Branch \"${branch}\" $(
if test -n "${default_branch}"; then
    echo "and \"${default_branch}\"";
fi
) not found in:
${remote_info}
############################################################

Please enter a branch name to pull (or leave empty to skip): " branch </dev/tty
        done

        if test -n "${branch:-}"; then
            echo "Pulling ${!repo_name} ${remote}/${branch}...";
            git -C ~/${!repo_path} pull --no-tags "${remote}" "${branch}";
            git -C ~/${!repo_path} submodule update --init --recursive;
        else
            echo "No alternate branch name supplied, skipping";
        fi;

    done
}

pull_repositories "$@" <&0;
