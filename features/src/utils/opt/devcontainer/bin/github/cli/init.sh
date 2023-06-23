#! /usr/bin/env bash

init_github_cli() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    if ! type gh > /dev/null 2>&1; then
        export GITHUB_USER="";
        return;
    fi

    local git_protocol="--git-protocol https";
    local avoid_gh_cli_ssh_keygen_prompt=;

    if [[ "${CODESPACES:-false}" == "true" ]]; then
        git_protocol="--git-protocol https";
    else
        if ssh -T git@${GITHUB_HOST:-github.com} 2>&1 | grep -q "You've successfully authenticated"; then
            git_protocol="--git-protocol ssh";
            if type ssh-keygen > /dev/null 2>&1; then
                avoid_gh_cli_ssh_keygen_prompt=1;
            fi
        fi
    fi

    scope_flags() {
        echo -n "$(echo -n "${@}" | xargs -r -n1 -d' ' echo -n ' --scopes')";
    }

    local active_scopes="$(GITHUB_TOKEN=     \
        gh api -i -X GET --silent rate_limit \
        2>/dev/null                          \
      | grep -i 'x-oauth-scopes:'            \
      | cut -d' ' -f1 --complement           \
      | tr -d ','                            \
    )";

    local needed_scopes="read:org";

    needed_scopes="$(                                                  \
      comm -23                                                         \
        <(echo -n "${needed_scopes}" | xargs -r -n1 -d' ' echo | sort) \
        <(echo -n "${active_scopes}" | xargs -r -n1 -d' ' echo | sort) \
    )";

    if [ -n "${needed_scopes}" ]; then
        local VAR;
        for VAR in GH_TOKEN GITHUB_TOKEN; do
            if [[ -n "$(eval "echo \${${VAR}:-}")" ]]; then
                for ENVFILE in /etc/profile "$HOME/.bashrc"; do
                    if [[ "$(grep -q -E "^${VAR}=$" "$ENVFILE" >/dev/null 2>&1; echo $?)" != 0 ]]; then
                        echo "${VAR}=" | sudo tee -a "$ENVFILE" >/dev/null || true;
                    fi
                done
                unset ${VAR};
            fi
        done
    fi

    if ! gh auth status >/dev/null 2>&1; then
        echo "Logging into GitHub..." >&2;

        local ssh_keygen="$(which ssh-keygen || echo "")";

        if [ -n "${ssh_keygen}" ] \
        && [ -n "${avoid_gh_cli_ssh_keygen_prompt}" ]; then
            sudo mv $ssh_keygen{,.bak} || true;
        fi

        gh auth login \
            --web ${git_protocol} \
            --hostname "${GITHUB_HOST:-github.com}" \
            $(scope_flags ${active_scopes} ${needed_scopes}) \
        || echo "Continuing without logging into GitHub";

        if [ -n "${ssh_keygen}" ] \
        && [ -n "${avoid_gh_cli_ssh_keygen_prompt}" ]; then
            sudo mv $ssh_keygen{.bak,} || true;
        fi
    elif [ -n "${needed_scopes}" ]; then
        echo "Logging into GitHub..." >&2;
        gh auth refresh \
            --hostname "${GITHUB_HOST:-github.com}" \
            $(scope_flags ${active_scopes} ${needed_scopes}) \
        || echo "Continuing without logging into GitHub";
    fi

    if gh auth status >/dev/null 2>&1; then
        gh auth setup-git --hostname "${GITHUB_HOST:-github.com}";
    fi

    local github_user="${GITHUB_USER:-}";

    if [ -z "${github_user:-}" ]; then
        if [ -f ~/.config/gh/hosts.yml ]; then
            github_user="$(grep --color=never 'user:' ~/.config/gh/hosts.yml | cut -d ':' -f2 | tr -d '[:space:]' || echo '')";
        fi
    fi

    if [ -z "${github_user:-}" ]; then
        github_user="$(gh api user --jq '.login // ""' 2>/dev/null || echo)";
    fi

    export GITHUB_USER="${github_user}";
}

init_github_cli "$@";
