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

    source devcontainer-utils-init-gitlab-cli;

    # PS4='+ ${LINENO}: '; set -x;

    local branch="";

    eval "$(                                  \
        devcontainer-utils-parse-args         \
            --names 'b|branch' "$@"           \
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
    local name="$(get_repo_name "${upstream}")";
    local owner="$(get_repo_owner "${upstream}")";
    local user="${GITLAB_USER:-"${owner}"}";
    local fork="$(get_user_fork_name "${owner}" "${name}" "${user}")";

    if [ -n "${fork:-}" ]; then
        origin="${fork}";
    else
        while true; do
            local CHOICE;
            read -p "'${GITLAB_HOST:-gitlab.com}/${user}/${name}.git' not found.
    Fork '${upstream}' into '${user}/${name}' now (y/n)? " CHOICE </dev/tty
            case "${CHOICE:-}" in
                [Nn]* ) origin="${upstream}"; break;;
                [Yy]* ) origin="${user}/${name}";
                        glab repo fork "${upstream}" --clone=false;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
        done
    fi

    if [ "$(glab config get git_protocol)" = "ssh" ]; then
        origin="$(get_repo_ssh_url "${origin}")";
        upstream="$(get_repo_ssh_url "${upstream}")";
    else
        origin="$(get_repo_git_url "${origin}")";
        upstream="$(get_repo_git_url "${upstream}")";
    fi

    devcontainer-utils-clone-git-repo \
        --upstream "${upstream}"      \
        --branch "${branch}"          \
        ${__rest__[@]}                \
        "${origin}" "${directory}"    ;
}

clone_gitlab_repo "$@";
