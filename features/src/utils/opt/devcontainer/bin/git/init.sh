#! /usr/bin/env bash

init_git_cli_config() {

    set -euo pipefail;

    git config --global codespaces-theme.hide-status    "${CODESPACES_THEME_HIDE_STATUS:-1}";
    git config --global devcontainers-theme.show-dirty  "${DEVCONTAINERS_THEME_SHOW_DIRTY:-0}";
    git config --global devcontainers-theme.hide-status "${DEVCONTAINERS_THEME_HIDE_STATUS:-1}";

    if [[ -z "$(git config --get pull.rebase)" ]]; then
        git config --global pull.rebase false;
    fi

    if [[ -z "$(git config --get user.name)" ]]; then
        eval "export $(devcontainer-utils-init-github-cli)";
        if [[ -z "$GITHUB_USER" ]]; then exit 1; fi
        local git_user_name="$(gh api user --jq '.name')";
        if [[ $? != 0 ]]; then git_user_name=""; fi;
        if [[ -z "$git_user_name" && -t 0 && "${CODESPACES:-false}" != true ]]; then
            read -p "Git user.name: " git_user_name </dev/tty;
        fi
        git config --global user.name "${git_user_name:-anon}";
    fi

    if [[ -z "$(git config --get user.email)" ]]; then
        local git_user_email="";
        if [[ -z "$git_user_email" && -t 0 && "${CODESPACES:-false}" != true ]]; then
            read -p "Git user.email: " git_user_email </dev/tty;
        fi
        git config --global user.email "${git_user_email:-users.noreply.github.com}";
    fi
}

(init_git_cli_config "$@");
