#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-clone-gitlab-repo [OPTION]... [--] <upstream> [<directory>]
#
# Clone a GitLab repository for the logged in user (as reported by `glab auth status`).
#
# If the user doesn't have a fork of the repository, notify the user and ask whether they would like to fork it.
#
# Boolean options:
#  -h,--help                    Print this text.
#  -q,--quiet                   Operate quietly. Progress is not reported to the standard error stream.
#  --no-fork                    Don't prompt the user to fork the repo if a user fork isn't found.
#                               (default: false)
#  --clone-upstream             Always clone the upstream, not the user's fork.
#                               (default: false)
#
# Options that require values:
#  -b,--branch <branch_or_tag>  Check the repo out to <branch_or_tag>.
#  -j,--jobs,--parallel <num>   Clone <num> submodules in parallel
#  --ssh-url <url>              FQDN of the GitLab instance when cloning via SSH.
#  --https-url <url>            FQDN of the GitLab instance when cloning via HTTPS.
#
# Positional arguments:
#  upstream                     Set <upstream> as the `upstream` remote.
#  directory                    Clone the repo into <directory>.

get_default_branch() {
    local repo="${1}";
    glab api graphql --hostname "${https_url}" -f query="$(cat <<________EOF | tr -s '[:space:]'
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
    glab api graphql --hostname "${https_url}" -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                path
            }
        }
________EOF
    )" \
  | jq -r '.data.project.path';
}

get_repo_owner() {
    local repo="${1}";
    glab api graphql --hostname "${https_url}" -f query="$(cat <<________EOF | tr -s '[:space:]'
        query {
            project(fullPath: "${repo}") {
                namespace {
                    fullPath
                }
            }
        }
________EOF
    )" \
  | jq -r '.data.project.namespace.fullPath';
}

get_repo_git_url() {
    local repo="${1}";
    glab api graphql --hostname "${https_url}" -f query="$(cat <<________EOF | tr -s '[:space:]'
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
    glab api graphql --hostname "${https_url}" -f query="$(cat <<________EOF | tr -s '[:space:]'
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
        glab api --hostname "${https_url}" "projects/$(jq -rn --arg x "${owner}/${name}" '$x|@uri')/forks?owned=true" | jq -r '. | map(.path_with_namespace)[]';
    fi
}

clone_gitlab_repo() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -q,--quiet
        -j,--jobs,--parallel
    ' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'clone clone-gitlab-repo';

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi;

    local upstream="${REST[0]:?"fatal: missing required positional argument <upstream>"}";

    if test "${#REST[@]}" -gt 1; then REST=("${REST[@]:1}"); fi

    local origin="${upstream}";
    local fork=;
    local name=;
    local user=;
    local owner=;

    ssh_url="${ssh_url:-${GITLAB_HOST:-gitlab.com}}";
    https_url="${https_url:-${GITLAB_HOST:-gitlab.com}}";

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
        branch="${branch:-"$(get_default_branch "${upstream}")"}";
        fork="$(get_user_fork_name "${owner}" "${name}" "${user}")";
    fi

    if test -n "${fork:-}"; then
        origin="${fork}";
    elif test -z "${no_fork:-}" && \
         test -z "${clone_upstream:-}" && \
         devcontainer-utils-shell-is-interactive; then
        while true; do
            local CHOICE;
            read -rsp "'${GITLAB_HOST:-gitlab.com}/${user}/${name}.git' not found.
    Fork '${upstream}' into '${user}/${name}' now (y/n)? " CHOICE <"$(tty)"
            case "${CHOICE:-}" in
                [Nn]* ) origin="${upstream}"; break;;
                [Yy]* ) origin="${user}/${name}";
                        GL_HOST="${https_url}" glab repo fork "${upstream}" --clone=false;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
        done
    fi

    local origin_;
    local upstream_;

    if test -z "${no_fork:-}" && \
       test -z "${clone_upstream:-}" && \
     ! glab auth status --hostname "${https_url}"  2>&1 | grep -q "No token provided"; then
        if [ "$(glab config get git_protocol --host "${https_url}")" = "ssh" ]; then
            origin_="$(get_repo_ssh_url "${origin}")";
            upstream_="$(get_repo_ssh_url "${upstream}")";
        else
            origin_="$(get_repo_git_url "${origin}")";
            upstream_="$(get_repo_git_url "${upstream}")";
        fi
    fi

    if test -z "${origin_:-}" || test -z "${upstream_:-}"; then
        if [ "$(glab config get git_protocol --host "${https_url}")" = "ssh" ]; then
            origin_="${origin_:-"ssh://git@${ssh_url}/${origin}.git"}";
            upstream_="${upstream_:-"ssh://git@${ssh_url}/${upstream}.git"}";
        else
            origin_="${origin_:-"https://${https_url}/${origin}.git"}";
            upstream_="${upstream_:-"https://${https_url}/${upstream}.git"}";
        fi
    fi

    devcontainer-utils-clone-git-repo          \
        ${branch:+--branch "${branch}"}        \
        ${upstream:+--upstream "${upstream_}"} \
        "${OPTS[@]}"                           \
        --                                     \
        "${origin_}" "${REST[@]}"              \
        ;
}

clone_gitlab_repo "$@" <&0;
