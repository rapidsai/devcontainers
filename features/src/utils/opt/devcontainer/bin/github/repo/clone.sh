#! /usr/bin/env bash

get_default_branch() {
    local repo="${1}";
    gh repo view "${repo}" --json defaultBranchRef --jq '.defaultBranchRef.name';
}

get_repo_name() {
    local repo="${1}";
    gh repo view "${repo}" --json 'name' --jq '.name';
}

get_repo_owner() {
    local repo="${1}";
    gh repo view "${repo}" --json 'owner' --jq '.owner.login';
}

get_repo_git_url() {
    local repo="${1}";
    echo "$(gh repo view "${repo}" --json url --jq ".url").git";
}

get_repo_ssh_url() {
    local repo="${1}";
    gh repo view "${repo}" --json sshUrl --jq ".sshUrl";
}

get_user_fork_name() {
    local owner="${1}";
    local name="${2}";
    local user="${3}";
    if [ "${user}" = "${owner}" ]; then
        echo "${owner}/${name}";
    else
        local query="$(cat <<________EOF | tr -s '[:space:]'
            | map(select(
                .parent.name == "${name}"
                and
                .parent.owner.login == "${owner}"
              ))
            | map(.nameWithOwner)[]
________EOF
        )";
        local nameWithOwner="$(gh repo list "${user}" --fork --json nameWithOwner --json parent --jq ". ${query}" 2>/dev/null || echo "err")";
        if [ "${nameWithOwner}" = "err" ]; then
            nameWithOwner="";
            for repo in $(gh repo list "${user}" --fork --json name --jq 'map(.name)[]'); do
                nameWithOwner="$(gh repo view "${repo}" --json nameWithOwner --json parent --jq "[.] ${query}" 2>/dev/null || echo "")";
                if test -n "${nameWithOwner}"; then
                    break;
                fi
            done
        fi
        echo -n "${nameWithOwner:-}";
    fi
}

clone_github_repo() {

    set -euo pipefail;

    local branch=;
    local no_fork=;
    local clone_upstream=;

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            b|branch                          |
            no-fork                           |
            clone-upstream                    |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    local nargs="${#__rest__[@]}";
    local upstream="${__rest__[$((nargs - 2))]}";
    upstream="${upstream:?upstream is required}";

    branch="${b:-"${branch:-"$(get_default_branch "${upstream}")"}"}";

    local directory="${__rest__[$((nargs - 1))]}";
    directory="${directory:?directory is required}";

    __rest__=("${__rest__[@]/"${upstream}"}");
    __rest__=("${__rest__[@]/"${directory}"}");

    local origin="${upstream}";
    local name=;
    local user=;
    local fork=;
    local owner=;

    if test -z "${no_fork:-}" && \
       test -z "${clone_upstream:-}" && \
       devcontainer-utils-shell-is-interactive; then
        # shellcheck disable=SC1091
        . devcontainer-utils-init-github-cli;
        user="${GITHUB_USER:-}";
    fi

    if test -n "${clone_upstream:-}"; then
        fork="${upstream}";
    else
        name="$(get_repo_name "${upstream}")";
        owner="$(get_repo_owner "${upstream}")";
        user="${GITHUB_USER:-"${owner}"}";
        fork="$(get_user_fork_name "${owner}" "${name}" "${user}")";
    fi

    if test -n "${fork:-}"; then
        origin="${fork}";
    elif test -z "${no_fork:-}" && \
         test -z "${clone_upstream:-}" && \
         devcontainer-utils-shell-is-interactive; then
        while true; do
            local CHOICE;
            read -rp "'${GITHUB_HOST:-github.com}/${user}/${name}.git' not found.
    Fork '${upstream}' into '${user}/${name}' now (y/n)? " CHOICE <$(tty)
            case "${CHOICE:-}" in
                [Nn]* ) origin="${upstream}"; break;;
                [Yy]* ) origin="${user}/${name}";
                        gh repo fork "${upstream}" --clone=false --default-branch-only;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
        done
    fi

    if gh auth status >/dev/null 2>&1; then
        if [ "$(gh config get git_protocol)" = "ssh" ]; then
            origin="$(get_repo_ssh_url "${origin}")";
            upstream="$(get_repo_ssh_url "${upstream}")";
        else
            origin="$(get_repo_git_url "${origin}")";
            upstream="$(get_repo_git_url "${upstream}")";
        fi
    else
        origin="https://${GITHUB_HOST:-github.com}/${origin}.git";
        upstream="https://${GITHUB_HOST:-github.com}/${upstream}.git";
    fi

    devcontainer-utils-clone-git-repo \
        --upstream "${upstream}"      \
        --branch "${branch}"          \
        ${__rest__[@]}                \
        "${origin}" "${directory}"    ;
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_github_repo "$@";
