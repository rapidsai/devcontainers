#!/usr/bin/env bash

# Usage:
#  rapids-checkout-same-branch [OPTION]...
#
# Fetch all branches from the origin and upstream remotes,
# prompts the user to select a branch they all have in common.
# then checks out all repositories to this common branch.
#
# Boolean options:
#  -h,--help          Print this text.
#
# Options that require values:
#  -j,--parallel <num>   Fetch <num> repos in parallel.
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

# Function to convert ucx branch names
convert-ucx-branch() {
    repo=$1
    custom_branch=$2
    normalized_branch="${custom_branch}"

    if [[ "${repo}" == "ucx"* ]]; then
        # Only convert branches that match the pattern release/YY.MM
        if [[ "${custom_branch}" =~ ^release/[0-9]{2}\.[0-9]{2}$ ]]; then
            RAPIDS_VERSION=$(echo "${custom_branch}" | awk '{split($0, a, "/"); print a[2]}')
            # Get UCX version associated w/ RAPIDS version
            UCX_VERSION="$(curl -sL https://version.gpuci.io/rapids/${RAPIDS_VERSION})"
            normalized_branch="release/${UCX_VERSION}"
        fi
    fi

    echo "${normalized_branch}"
}

checkout_same_branch() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(                                              \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc --all)}      \
        rapids-get-num-archs-jobs-and-load --archs 0 "$@" \
    )";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'checkout-same-branch';

    echo "Determining available branches...";

    local repo_names=();
    local repo_paths=();
    local repo_pairs=();
    for ((i=0; i < ${repos_length:-0}; i+=1)); do
        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";
        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi
        local name="${!repo_name}";
        local path="${!repo_path}";

        # Skip ucxx repositories when determining common branches
        if [[ "${name}" == "ucx"* ]]; then
            continue;
        fi

        repo_names+=("${name}");
        repo_paths+=("${path}");
        repo_pairs+=("${name//"-"/"_"} ${path}");
    done

    eval "$(
        echo -e "${repo_pairs[@]/%/\\n}"                                                              \
      | xargs -r -P"${n_jobs-}" -I% bash -c "                                                         \
        name=\$(cut -d' ' -f1 <<< \$0);                                                               \
        path=\$(cut -d' ' -f2 <<< \$0);                                                               \
        echo \"local repo_branches_\${name}_='\$(                                                     \
            cat <(git -C ~/\${path} ls-remote -h origin | cut -f2 | sed \"s@refs/heads@origin@\")     \
                <(git -C ~/\${path} ls-remote -h upstream | cut -f2 | sed \"s@refs/heads@upstream@\") \
          | grep -Pv \"(/pull-request/|master|main)\" | tr '[:space:]' ' '                            \
        )'\"                                                                                          \
        " %
    )";

    local repo_branches=;
    local common_branches=;

    for repo_branches in ${!repo_branches_*}; do

        if test "${#common_branches}" -eq 0; then
            # start with first repo's set of branches
            common_branches="$(\
                echo "${!repo_branches}"       \
              | xargs -r -n1                   \
              | sort -V --parallel="${n_jobs}" \
              | tr '[:space:]' ' '             \
            )";
        else
            # get a sorted set of branches common to all repos up to this point
            common_branches="$(\
                echo "${common_branches} ${!repo_branches}" \
              | xargs -r -n1                                \
              | sort -V --parallel="${n_jobs}"              \
              | uniq -d                                     \
              | tr '[:space:]' ' '                          \
            )";
        fi

        if test "${#common_branches}" -eq 0; then
            echo "No branches in common for repos: ${repo_names[*]}" >&2;
            exit 1;
        fi
    done

    echo "Found branches in common for: ${repo_names[*]}";
    echo "Please select a branch to check out:";

    # local branches=($(echo "${common_branches}" | xargs -r -n1 | sort -Vr --parallel=${n_jobs}));
    local -a branches=();
    readarray -t branches < <(echo "${common_branches}" | xargs -r -n1 | sort -Vr --parallel="${n_jobs}");
    local branch_name="";

    select branch_name in "${branches[@]}" "Quit"; do
        if [[ $REPLY -lt $(( ${#branches[@]}+1 )) ]]; then
            break;
        elif [[ $REPLY -eq $(( ${#branches[@]}+1 )) ]]; then
            exit 0;
        else
            echo "Invalid option, please select a branch (or quit)";
        fi
    done;

    echo "Starting checkout."

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [[ ! -d ~/"${!repo_path:-}/.git" ]]; then
            continue;
        fi

        local remote="${branch_name/\/*}";
        local branch="${branch_name/#"${remote}/"}";

        # Apply normalization for ucxx repositories
        local repo_name_val="${!repo_name}";
        local normalized_branch;
        normalized_branch=$(convert-ucx-branch "${repo_name_val}" "${branch}");

        if [[ "${repo_name_val}" == "ucx"* ]]; then
            echo "Using normalized branch '${normalized_branch}' for repository '${repo_name_val}'";
            branch="${normalized_branch}";
        fi

        git -C ~/${!repo_path} fetch "${remote}" "refs/heads/${branch}";

        if ! git -C ~/${!repo_path} checkout -b "${branch}" -t "${remote}/${branch}" 2>/dev/null; then
            git -C ~/${!repo_path} checkout "${branch}";
            git -C ~/${!repo_path} branch "${branch}" -u "${remote}/${branch}";
        fi

        git -C ~/${!repo_path} submodule update --init --recursive -j "${n_jobs}";
    done;
}

checkout_same_branch "$@" <&0;
