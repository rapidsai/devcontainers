#! /usr/bin/env bash

_add_warning_to_bashrc() {
    if ! grep -q devcontainer-utils-print-missing-gitlab-token-warning ~/.bashrc; then
        echo 'devcontainer-utils-print-missing-gitlab-token-warning;' >> ~/.bashrc;
    fi
}

_remove_warning_from_bashrc() {
    if grep -q devcontainer-utils-print-missing-gitlab-token-warning ~/.bashrc; then
        sed -i 's@devcontainer-utils-print-missing-gitlab-token-warning;@@g' ~/.bashrc;
    fi
}

init_gitlab_cli() {
    local -;
    set -euo pipefail;

    if ! type glab > /dev/null 2>&1; then
        export GITLAB_USER="";
        return;
    fi

    if glab auth status 2>&1 | grep -q "No token provided"; then
        if [ -z "${GITLAB_TOKEN:-}" ]; then
            devcontainer-utils-print-missing-gitlab-token-warning;
            if ! devcontainer-utils-shell-is-interactive; then
                _add_warning_to_bashrc;
                export GITLAB_USER=;
                return;
            else
                read -rsp "Please enter a GitLab API token (or leave blank to skip): " GITLAB_TOKEN <"$(tty)";
            fi
        fi

        glab auth login \
            --hostname "${GITLAB_HOST:-gitlab.com}" \
            --stdin <<< "${GITLAB_TOKEN:-}" \
        || echo "Continuing without logging into GitLab";
    fi

    local gitlab_user="${GITLAB_USER:-}";

    if [ -z "${gitlab_user:-}" ]; then
        if [ -f ~/.config/glab-cli/config.yml ]; then
            gitlab_user="$(grep --color=never 'user:' ~/.config/glab-cli/config.yml | cut -d ':' -f2 | tr -d '[:space:]' || echo '')";
        fi
    fi

    if [ -z "${gitlab_user:-}" ]; then
        gitlab_user="$(glab api user 2>/dev/null | jq -r '.username // ""')";
    fi

    if [ -n "${gitlab_user:-}" ]; then
        _remove_warning_from_bashrc;
    fi

    export GITLAB_USER="${gitlab_user}";
}

init_gitlab_cli "$@";
