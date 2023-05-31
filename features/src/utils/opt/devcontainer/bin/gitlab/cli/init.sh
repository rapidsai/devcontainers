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

    set -euo pipefail;

    PS4='+ ${LINENO}: '; set -x;

    if [ "${CODESPACES:-false}" = "true" ]; then
        if [ -z "${GITLAB_TOKEN:-}" ]; then
            if ! [ -t 0 ] || ! [ -t /dev/tty ]; then
                devcontainer-utils-print-missing-gitlab-token-warning;
                _add_warning_to_bashrc;
                exit 1;
            fi
        fi
    fi

    if glab auth status 2>&1 | grep -q "No token provided"; then
        if [ -z "${GITLAB_TOKEN:-}" ]; then
            glab auth login --hostname "${GITLAB_HOST:-gitlab.com}" || echo "Continuing without logging into GitLab";

        #     # Theoretically this should work, but glab CLI removes newlines in a way that `script` can't handle
        #     faketty() { script -qefc "$(printf "%q " "$@")" /dev/null; }
        #     faketty glab auth login --hostname "${GITLAB_HOST:-gitlab.com}" \
        #   | sed -u 's@openid profile read_user write_repository api@openid%20profile%20read_user%20write_repository%20api@' \
        #     `# rewriting redirect_url=http://localhost fails OAuth validation, so we run with --network=host instead`
        #     `# | sed -u "s@http://localhost@http://$(hostname -i)@"` \
        #  || echo "Continuing without logging into GitLab";
        else
            glab auth login --hostname "${GITLAB_HOST:-gitlab.com}" --stdin < <(echo "${GITLAB_TOKEN}") || echo "Continuing without logging into GitLab";
        fi
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
