#! /usr/bin/env bash

init_git_cli_config() {

    set -euo pipefail;

    git config --global codespaces-theme.hide-status    "${CODESPACES_THEME_HIDE_STATUS:-1}" >/dev/null 2>&1 || true;
    git config --global devcontainers-theme.show-dirty  "${DEVCONTAINERS_THEME_SHOW_DIRTY:-0}" >/dev/null 2>&1 || true;
    git config --global devcontainers-theme.hide-status "${DEVCONTAINERS_THEME_HIDE_STATUS:-1}" >/dev/null 2>&1 || true;

    if [[ -z "$(git config --get pull.rebase)" ]]; then
        git config --global pull.rebase false >/dev/null 2>&1 || true;
    fi

    if [[ -z "$(git config --get user.name)" ]]; then
        source devcontainer-utils-init-github-cli;
        if [ -z "${GITHUB_USER:-}" ]; then exit 1; fi
        local git_user_name="$(gh api user --jq '.name')";
        if [[ $? != 0 ]]; then git_user_name=""; fi;
        if [ -t 0 ]                              \
        && [ -t /dev/tty ]                       \
        && [ -z "${git_user_name}" ]             \
        && [ "${CODESPACES:-false}" -neq "true" ]; then
            read -p "Git user.name: " git_user_name </dev/tty;
        fi
        git config --global user.name "${git_user_name:-anon}" >/dev/null 2>&1 || true;
    fi

    if [[ -z "$(git config --get user.email)" ]]; then
        local git_user_email="";
        if [ -t 0 ]                              \
        && [ -t /dev/tty ]                       \
        && [ -z "${git_user_email}" ]            \
        && [ "${CODESPACES:-false}" -neq "true" ]; then
            read -p "Git user.email: " git_user_email </dev/tty;
        fi
        git config --global user.email "${git_user_email:-users.noreply.${GITHUB_HOST:-github.com}}" >/dev/null 2>&1 || true;
    fi
}

init_git_cli_config "$@";
