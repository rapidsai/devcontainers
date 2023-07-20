#! /usr/bin/env bash

init_git_cli_config() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    if ! test -f ~/.gitconfig; then
        if test -f ~/.gitconfig.default; then
            cp -a ~/.gitconfig{.default,};
        fi
    fi

    if test -n "${SSH_AUTH_SOCK:-}" && type ssh-add >/dev/null 2>&1; then
        mkdir -p ~/.config/git;
        git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers;
        awk 'BEGIN {FS=" "; OFS=" "} {print $3, $1, $2}' <(ssh-add -L) > ~/.config/git/allowed_signers;
    fi

    if [ -z "$(git config --get user.name)" ]; then
        local git_user_name_default="anon";
        local git_user_name="${git_user_name_default}";
        if devcontainer-utils-shell-is-interactive; then
            read -p "Git user.name (${git_user_name_default}): " git_user_name <$(tty);
        fi
        git config --global user.name "${git_user_name:-"${git_user_name_default}"}" >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get user.email)" ]; then
        local git_user_email_default="users.noreply.${GITHUB_HOST:-github.com}";
        local git_user_email="${git_user_email_default}";
        if devcontainer-utils-shell-is-interactive; then
            read -p "Git user.email (${git_user_email_default}): " git_user_email <$(tty);
        fi
        git config --global user.email "${git_user_email:-"${git_user_email_default}"}" >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get pull.rebase)" ]; then
        git config --global pull.rebase false >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get codespaces-theme.hide-status)" ]; then
        git config --global codespaces-theme.hide-status    "${CODESPACES_THEME_HIDE_STATUS:-1}" >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get devcontainers-theme.show-dirty)" ]; then
        git config --global devcontainers-theme.show-dirty  "${DEVCONTAINERS_THEME_SHOW_DIRTY:-0}" >/dev/null 2>&1 || true;
    fi

    if [ -z "$(git config --get devcontainers-theme.hide-status)" ]; then
        git config --global devcontainers-theme.hide-status "${DEVCONTAINERS_THEME_HIDE_STATUS:-1}" >/dev/null 2>&1 || true;
    fi
}

(init_git_cli_config "$@");
