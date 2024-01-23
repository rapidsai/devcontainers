#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-clone-gitlab-repo [OPTION]... <upstream> <directory>
#
# Clone a GitLab repository for the logged in user (as reported by `glab auth status`).
#
# If the user doesn't have a fork of the repository, notify the user and ask whether they would like to fork it.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  --no-fork                    don't prompt the user to fork the repo if a user fork isn't found
#                               (default: false)
#  --no-update-env              don't update the Python env with the repo's dependencies after cloning
#                               (default: false)
#  --clone-upstream             always clone the upstream, not the user's fork
#                               (default: false)
#
# Options that require values:
#  -b,--branch <branch_or_tag>  check the repo out to <branch_or_tag>
#
# Positional arguments:
#  upstream                     set <upstream> as the `upstream` remote
#  directory                    clone the repo into <directory>

. devcontainer-utils-parse-args-from-docstring;

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
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local nargs="${#__rest__[@]}";
    local upstream="${__rest__[$((nargs - 2))]}";
    upstream="${upstream:?upstream is required}";

    local no_fork="${no_fork:-}";
    local clone_upstream="${clone_upstream:-}";
    local branch="${b:-"${branch:-"$(get_default_branch "${upstream}")"}"}";

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
        source devcontainer-utils-init-gitlab-cli;
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
            read -p "'${GITLAB_HOST:-gitlab.com}/${user}/${name}.git' not found.
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

if test -n "${devcontainer_utils_debug:-}" \
&& ( test -z "${devcontainer_utils_debug##*"all"*}" \
  || test -z "${devcontainer_utils_debug##*"clone"*}" \
  || test -z "${devcontainer_utils_debug##*"clone-gitlab-repo"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_gitlab_repo "$@";
