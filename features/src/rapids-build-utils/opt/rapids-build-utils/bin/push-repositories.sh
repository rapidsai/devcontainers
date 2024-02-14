#!/usr/bin/env bash

# Usage:
#  rapids-push-repositories [OPTION]...
#
# Push the latest commits from each repository to the origin remote.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

push_repositories() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'push-repositories';

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

push_repositories "$@" <&0;
