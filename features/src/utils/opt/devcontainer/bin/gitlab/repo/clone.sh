#! /usr/bin/env bash

get_default_branch() {
    local repo="${1}";
    glab api graphql -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                repository {
                    rootRef
                }
            }
        }
________EOF
    )" \
  | jq -r '.data.project.repository.rootRef';
}

get_repo_name() {
    local repo="${1}";
    glab api graphql -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                name
            }
        }
________EOF
    )" \
  | jq -r '.data.project.name';
}

get_repo_owner() {
    local repo="${1}";
    glab api graphql -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                group {
                    name
                }
            }
        }
________EOF
    )" \
  | jq -r '.data.project.group.name';
}

get_repo_git_url() {
    local repo="${1}";
    glab api graphql -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                httpUrlToRepo
            }
        }
________EOF
    )" \
  | jq -r '.data.project.httpUrlToRepo';

}

get_repo_ssh_url() {
    local repo="${1}";
    glab api graphql -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                sshUrlToRepo
            }
        }
________EOF
    )" \
  | jq -r '.data.project.sshUrlToRepo';
}

get_user_fork_name() {
    local owner="${1}";
    local name="${2}";
    local user="${3}";
    if [ "${user}" = "${owner}" ]; then
        echo "${owner}/${name}";
    else
        glab api "projects/$(jq -rn --arg x "${owner}/${name}" '$x|@uri')/forks?owned=true" | jq -r '. | map(.path_with_namespace)[]';
    fi
}

clone_gitlab_repo() {

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
    local fork=;
    local name=;
    local user=;
    local owner=;

    if test -z "${no_fork:-}" && \
       test -z "${clone_upstream:-}" && \
       devcontainer-utils-shell-is-interactive; then
        # shellcheck disable=SC1091
        . devcontainer-utils-init-gitlab-cli;
        user="${GITLAB_USER:-}";
    fi

    if test -n "${clone_upstream:-}"; then
        fork="${upstream}";
    else
        name="$(get_repo_name "${upstream}")";
        owner="$(get_repo_owner "${upstream}")";
        user="${GITLAB_USER:-"${owner}"}";
        fork="$(get_user_fork_name "${owner}" "${name}" "${user}")";
    fi

    if test -n "${fork:-}"; then
        origin="${fork}";
    elif test -z "${no_fork:-}" && \
         test -z "${clone_upstream:-}" && \
         devcontainer-utils-shell-is-interactive; then
        while true; do
            local CHOICE;
            read -rp "'${GITLAB_HOST:-gitlab.com}/${user}/${name}.git' not found.
    Fork '${upstream}' into '${user}/${name}' now (y/n)? " CHOICE <$(tty)
            case "${CHOICE:-}" in
                [Nn]* ) origin="${upstream}"; break;;
                [Yy]* ) origin="${user}/${name}";
                        glab repo fork "${upstream}" --clone=false;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
        done
    fi

    if ! glab auth status 2>&1 | grep -q "No token provided"; then
        if [ "$(glab config get git_protocol)" = "ssh" ]; then
            origin="$(get_repo_ssh_url "${origin}")";
            upstream="$(get_repo_ssh_url "${upstream}")";
        else
            origin="$(get_repo_git_url "${origin}")";
            upstream="$(get_repo_git_url "${upstream}")";
        fi
    else
        origin="https://${GITLAB_HOST:-gitlab.com}/${origin}.git";
        upstream="https://${GITLAB_HOST:-gitlab.com}/${upstream}.git";
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

clone_gitlab_repo "$@";
