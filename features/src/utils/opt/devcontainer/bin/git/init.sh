#! /usr/bin/env bash

set -euo pipefail;

git config --global codespaces-theme.hide-status 1;
git config --global devcontainers-theme.hide-status 1;
git config --global devcontainers-theme.show-dirty 0;

if [[ -z "$(git config --get pull.rebase)" ]]; then
    git config --global pull.rebase false;
fi

if [[ -z "$(git config --get user.name)" ]]; then
    . /opt/devcontainer/bin/github/cli/init.sh;
    git_user_name="$(gh api user --jq '.name')";
    if [[ $? != 0 ]]; then git_user_name=""; fi;
    if [[ -z "$git_user_name" && -t 0 && "${CODESPACES:-false}" != true ]]; then
        read -p "Git user.name: " git_user_name </dev/tty;
    fi
    git config --global user.name "${git_user_name:-anon}";
    unset git_user_name;
fi

if [[ -z "$(git config --get user.email)" ]]; then
    . /opt/devcontainer/bin/github/cli/init.sh;
    git_user_email="$(gh api user/emails --jq '. | map(select(.primary == true)) | map(.email)[]')";
    if [[ $? != 0 ]]; then git_user_email=""; fi;
    if [[ -z "$git_user_email" && -t 0 && "${CODESPACES:-false}" != true ]]; then
        read -p "Git user.email: " git_user_email </dev/tty;
    fi
    git config --global user.email "${git_user_email:-users.noreply.github.com}";
    unset git_user_email;
fi
