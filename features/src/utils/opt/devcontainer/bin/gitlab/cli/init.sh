#! /usr/bin/env bash

_add_warning_to_bashrc() {
    if [[ "$(grep -q devcontainer-utils-print-missing-gitlab-token-warning ~/.bashrc; echo $?)" == 1 ]]; then
        echo 'devcontainer-utils-print-missing-gitlab-token-warning;' >> ~/.bashrc;
    fi
}

_remove_warning_from_bashrc() {
    if [[ "$(grep -q devcontainer-utils-print-missing-gitlab-token-warning ~/.bashrc; echo $?)" == 0 ]]; then
        sed -i 's@devcontainer-utils-print-missing-gitlab-token-warning;@@g' ~/.bashrc;
    fi
}

init_gitlab_cli() {

    set -euo pipefail;

    if [[ "${CODESPACES:-false}" == true ]]; then
        if [[ -z "${GITLAB_TOKEN:-}" ]]; then
            devcontainer-utils-print-missing-gitlab-token-warning;
            _add_warning_to_bashrc;
            return;
        fi
        glab config set --global git_protocol https;
    fi

    if [[ $(glab auth status 2>&1 | grep "No token provided" >/dev/null 2>&1; echo $?) == 0 ]]; then
        if [[ -z "${GITLAB_TOKEN:-}" ]]; then
            glab auth login --hostname gitlab.com;
        else
            glab auth login  --hostname gitlab.com --stdin < <(echo "${GITLAB_TOKEN}");
        fi
    fi

    local gitlab_user="${GITLAB_USER:-}";

    if [[ -z "${gitlab_user:-}" ]]; then
        if [[ -f ~/.config/glab-cli/config.yml ]]; then
            gitlab_user="$(grep --color=never 'user:' ~/.config/glab-cli/config.yml | cut -d ':' -f2 | tr -d '[:space:]' || echo '')";
        fi
    fi

    if [[ -z "${gitlab_user:-}" ]]; then
        gitlab_user="$(glab api user | jq -r '.username')";
    fi

    if [[ -n "${gitlab_user:-}" ]]; then
        _remove_warning_from_bashrc;
    fi

    echo "GITLAB_USER=${gitlab_user}";
}

(init_gitlab_cli "$@");
