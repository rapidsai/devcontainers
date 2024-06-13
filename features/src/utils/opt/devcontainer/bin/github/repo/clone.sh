#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-clone-github-repo [OPTION]... [--] <upstream> [<directory>]
#
# Clone a GitHub repository for the logged in user (as reported by `gh auth status`).
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
#  -j,--jobs,--parallel <num>   Clone <num> submodules in parallel.
#  --ssh-url <url>              FQDN of the GitHub instance when cloning via SSH.
#  --https-url <url>            FQDN of the GitHub instance when cloning via HTTPS.
#
# Positional arguments:
#  upstream                     Set <upstream> as the `upstream` remote.
#  directory                    Clone the repo into <directory>.

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
        local -r query="$(cat <<________EOF | tr -s '[:space:]'
            | map(select(
                .parent.name == "${name}"
                and
                .parent.owner.login == "${owner}"
              ))
            | map(.nameWithOwner)[]
________EOF
        )";
        local nameWithOwner;
        nameWithOwner="$(gh repo list --limit 9999 "${user}" --fork --json nameWithOwner --json parent --jq ". ${query}" 2>/dev/null || echo "err")";
        if [ "${nameWithOwner}" = "err" ]; then
            nameWithOwner="";
            # Work around https://github.com/cli/cli/issues/7881 by explicitly enumerating each user fork and checking the parent info
            for repo in $(gh repo list --limit 9999 "${user}" --fork --json name --jq 'map(.name)[]'); do
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
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -q,--quiet
        -j,--jobs,--parallel
    ' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'clone clone-github-repo';

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi;

    local upstream="${REST[0]:?"fatal: missing required positional argument <upstream>"}";

    if test "${#REST[@]}" -gt 1; then REST=("${REST[@]:1}"); fi

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
            read -rsp "'${GITHUB_HOST:-github.com}/${user}/${name}.git' not found.
    Fork '${upstream}' into '${user}/${name}' now (y/n)? " CHOICE <"$(tty)"
            case "${CHOICE:-}" in
                [Nn]* ) origin="${upstream}"; break;;
                [Yy]* ) origin="${user}/${name}";
                        gh repo fork "${upstream}" --clone=false --default-branch-only;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
        done
    fi

    local origin_;
    local upstream_;

    if test -z "${no_fork:-}" && \
       test -z "${clone_upstream:-}" && \
       gh auth status >/dev/null 2>&1; then
        if [ "$(gh config get git_protocol)" = "ssh" ]; then
            origin_="$(get_repo_ssh_url "${origin}")";
            upstream_="$(get_repo_ssh_url "${upstream}")";
        else
            origin_="$(get_repo_git_url "${origin}")";
            upstream_="$(get_repo_git_url "${upstream}")";
        fi
    fi

    if test -z "${origin_:-}" || test -z "${upstream_:-}"; then
        if [ "$(gh config get git_protocol)" = "ssh" ]; then
            origin_="${origin_:-"ssh://git@${ssh_url:-${GITHUB_HOST:-github.com}}/${origin}.git"}";
            upstream_="${upstream_:-"ssh://git@${ssh_url:-${GITHUB_HOST:-github.com}}/${upstream}.git"}";
        else
            origin_="${origin_:-"https://${https_url:-${GITHUB_HOST:-github.com}}/${origin}.git"}";
            upstream_="${upstream_:-"https://${https_url:-${GITHUB_HOST:-github.com}}/${upstream}.git"}";
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

clone_github_repo "$@" <&0;
