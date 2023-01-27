#! /usr/bin/env bash

set -euo pipefail;

git_protocol=
avoid_gh_cli_ssh_keygen_prompt=

if [[ "${CODESPACES:-false}" == true ]]; then
    git_protocol="--git-protocol https";
else
    ssh_result="$(ssh -T git@github.com 2>&1 || true)";
    ssh_success="You've successfully authenticated, but GitHub does not provide shell access.";
    if [[ "$(echo "$ssh_result" | grep -q "$ssh_success" &>/dev/null; echo $?)" == 0 ]]; then
        git_protocol="--git-protocol ssh";
        if type ssh-keygen > /dev/null 2>&1; then
            avoid_gh_cli_ssh_keygen_prompt=1;
        fi
    fi
    unset ssh_result;
    unset ssh_success;
fi

select_required_scopes() {
    local need="";
    local have="$(GITHUB_TOKEN=              \
        gh api -i -X GET --silent rate_limit \
        2>/dev/null                          \
      | grep -i 'x-oauth-scopes:'            \
    )";

    for scope in "$@"; do
        if [[ ! $have =~ $scope ]]; then
            need="${need:+$need }$scope";
        fi
    done

    echo -n "$(echo -n "$need" | xargs -r -n1 -d' ' echo -n ' --scopes')";
}

scopes="$(select_required_scopes "user:email" "read:org")";

if [[ -n "$scopes" ]]; then
    for VAR in GH_TOKEN GITHUB_TOKEN; do
        if [[ -n "$(eval "echo \${${VAR}:-}")" ]]; then
            for ENVFILE in /etc/profile "$HOME/.bashrc"; do
                if [[ "$(grep -q -E "^${VAR}=$" "$ENVFILE" &>/dev/null; echo $?)" != 0 ]]; then
                    echo "${VAR}=" | sudo tee -a "$ENVFILE" >/dev/null || true;
                fi
            done
            unset ${VAR};
        fi
    done
    unset VAR;
fi

if [[ $(gh auth status &>/dev/null; echo $?) != 0 ]]; then
    echo "Logging into GitHub...";
    ssh_keygen="$(which ssh-keygen || echo "")";
    if [[ -n "$avoid_gh_cli_ssh_keygen_prompt" && -n "$ssh_keygen" ]]; then
        sudo mv $ssh_keygen{,.bak} || true;
    fi
    gh auth login --hostname github.com --web ${git_protocol} ${scopes};
    if [[ -n "$avoid_gh_cli_ssh_keygen_prompt" && -n "$ssh_keygen" ]]; then
        sudo mv $ssh_keygen{.bak,} || true;
    fi
    unset ssh_keygen;
elif [[ -n "$scopes" ]]; then
    echo "Logging into GitHub...";
    gh auth refresh --hostname github.com ${scopes};
fi

unset scopes;
unset git_protocol;

gh auth setup-git --hostname github.com;

if [[ -z "${GITHUB_USER:-}" ]]; then
    if [[ -f ~/.config/gh/hosts.yml ]]; then
        GITHUB_USER="$(grep --color=never 'user:' ~/.config/gh/hosts.yml | cut -d ':' -f2 | tr -d '[:space:]' || echo '')";
    fi
fi

if [[ -z "${GITHUB_USER:-}" ]]; then
    GITHUB_USER="$(gh api user --jq '.login')";
fi

if [[ -z "${GITHUB_USER:-}" ]]; then
    exit 1;
fi

export GITHUB_USER;
