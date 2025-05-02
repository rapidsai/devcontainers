#! /usr/bin/env bash

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/../../update-envvars.sh";

init_github_cli() {
    local -;
    set -euo pipefail;

    if ! command -v gh > /dev/null 2>&1; then
        export GITHUB_USER="";
        return;
    fi

    local git_protocol="https";
    local avoid_gh_cli_ssh_keygen_prompt=;

    if "${CODESPACES:-false}"; then
        git_protocol="https";
    else
        if grep -q "You've successfully authenticated" <<< "$(ssh -T "git@${GITHUB_HOST:-github.com}" 2>&1)"; then
            git_protocol="ssh";
            if command -v ssh-keygen > /dev/null 2>&1; then
                avoid_gh_cli_ssh_keygen_prompt=1;
            fi
        fi
    fi

    read -ra needed_scopes <<< "${SCCACHE_BUCKET_GH_SCOPES:-"read:org"} ${SCCACHE_DIST_GH_SCOPES:-"read:enterprise"}";
    read -ra needed_scopes <<< "${needed_scopes[*]/#/--scopes }";

    local -a wanted_scopes="($(devcontainer-utils-github-user-scopes "${needed_scopes[@]}"))";
    read -ra wanted_scopes <<< "${wanted_scopes[*]/#/--scopes }";

    local -a needed_scopes="($(devcontainer-utils-github-user-scopes "${needed_scopes[@]}" --complement))";
    read -ra needed_scopes <<< "${needed_scopes[*]/#/--scopes }";

    if test "${#needed_scopes[@]}" -gt 0; then
        local VAR;
        for VAR in GH_TOKEN GITHUB_TOKEN; do
            if test -n "${!VAR:+x}"; then
                local "_${VAR}=${!VAR}";
                unset_envvar "$VAR";
                unset "$VAR";
            fi
        done
    fi

    # shellcheck disable=SC2068
    if ! gh auth status >/dev/null 2>&1; then
        echo "Logging into GitHub..." >&2;

        local -r ssh_keygen="$(which ssh-keygen 2>/dev/null || echo)";

        if test -n "${ssh_keygen:+x}" \
        && test -n "${avoid_gh_cli_ssh_keygen_prompt:+x}"; then
            sudo mv "${ssh_keygen}"{,.bak} || true;
        fi

        gh auth login                               \
            --web --git-protocol "${git_protocol}"  \
            --hostname "${GITHUB_HOST:-github.com}" \
            "${wanted_scopes[@]}"                   \
        || echo "Continuing without logging into GitHub";

        if test -n "${ssh_keygen:+x}" \
        && test -n "${avoid_gh_cli_ssh_keygen_prompt:+x}"; then
            sudo mv "${ssh_keygen}"{.bak,} || true;
        fi
    elif test "${#needed_scopes[@]}" -gt 0; then
        echo "Logging into GitHub..." >&2;
        gh auth refresh                             \
            --hostname "${GITHUB_HOST:-github.com}" \
            "${wanted_scopes[@]}"                   \
        || echo "Continuing without logging into GitHub";
    fi

    if test "${#needed_scopes[@]}" -gt 0; then
        local _VAR;
        for VAR in GH_TOKEN GITHUB_TOKEN; do
            local _VAR="_$VAR";
            if test -n "${!_VAR:+x}"; then
                export "$VAR=${!_VAR}";
                reset_envvar "$VAR";
                unset "${_VAR}"
            fi
        done
    fi

    if gh auth status >/dev/null 2>&1; then
        if test "$(gh config get git_protocol --host "${GITHUB_HOST:-github.com}")" != "${git_protocol}"; then
            gh config set git_protocol --host "${GITHUB_HOST:-github.com}" "${git_protocol}";
        fi
        if test "https" = "${git_protocol}" && ! git config credential.helper >/dev/null; then
            gh auth setup-git --hostname "${GITHUB_HOST:-github.com}";
        fi
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

    export GITHUB_USER="${github_user:-}";
}

init_github_cli "$@";
