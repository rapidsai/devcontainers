#! /usr/bin/env bash

set -euo pipefail;

_add_warning_to_bashrc() {
    if [[ "$(grep -q print-missing-gitlab-token-warning ~/.bashrc; echo $?)" == 1 ]]; then
        echo '/bin/bash /opt/devcontainer/bin/gitlab/print-missing-token-warning.sh' >> ~/.bashrc;
    fi
}

_remove_warning_from_bashrc() {
    if [[ "$(grep -q print-missing-gitlab-token-warning ~/.bashrc; echo $?)" == 0 ]]; then
        sed -i 's@/bin/bash /opt/devcontainer/bin/gitlab/print-missing-token-warning.sh@@g' ~/.bashrc;
    fi
}

if [[ "${CODESPACES:-false}" == true ]]; then
    if [[ -z "${GITLAB_TOKEN:-}" ]]; then
        /opt/devcontainer/bin/gitlab/print-missing-token-warning.sh;
        _add_warning_to_bashrc;
        exit 0;
    fi
    glab config set --global git_protocol https;
fi

if [[ $(glab auth status 2>&1 | grep "No token provided" &>/dev/null; echo $?) == 0 ]]; then
    if [[ -z "${GITLAB_TOKEN:-}" ]]; then
        glab auth login --hostname gitlab.com;
    else
        glab auth login  --hostname gitlab.com --stdin < <(echo $GITLAB_TOKEN);
    fi
fi

if [[ -z "${GITLAB_USER:-}" ]]; then
    if [[ -f ~/.config/glab-cli/config.yml ]]; then
        GITLAB_USER="$(grep --color=never 'user:' ~/.config/glab-cli/config.yml | cut -d ':' -f2 | tr -d '[:space:]' || echo '')";
    fi
fi

if [[ -z "${GITLAB_USER:-}" ]]; then
    GITLAB_USER="$(glab api user | jq -r '.username')";
fi

if [[ -z "${GITLAB_USER:-}" ]]; then
    exit 1;
fi

_remove_warning_from_bashrc;

export GITLAB_USER;
