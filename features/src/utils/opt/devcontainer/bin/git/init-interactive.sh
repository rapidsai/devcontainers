#! /usr/bin/env bash

init_git_cli_config_interactive() {
    local -;
    set -euo pipefail;

    if [ -z "$(git config --get user.name)" ]; then
        local git_user_name_default="anon";
        local git_user_name="${git_user_name_default}";
        if devcontainer-utils-shell-is-interactive; then
            read -rsp "Git user.name (${git_user_name_default}): " git_user_name <$(tty);
        fi
        git config --global user.name "${git_user_name:-"${git_user_name_default}"}" >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get user.email)" ]; then
        local git_user_email_default="users.noreply.${GITHUB_HOST:-github.com}";
        local git_user_email="${git_user_email_default}";
        if devcontainer-utils-shell-is-interactive; then
            read -rsp "Git user.email (${git_user_email_default}): " git_user_email <$(tty);
        fi
        git config --global user.email "${git_user_email:-"${git_user_email_default}"}" >/dev/null 2>&1 || true;
    fi
}

init_git_cli_config_interactive "$@";
