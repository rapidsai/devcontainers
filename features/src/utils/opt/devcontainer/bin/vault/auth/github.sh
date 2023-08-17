#! /usr/bin/env bash


get_vault_token() {

    set -euo pipefail;

    local VAULT_HOST="$1";
    local user_orgs="${@:2}";
    local gh_token="$(gh auth token)";
    local vault_token=null;
    local org;

    for org in ${user_orgs}; do
        for org in $(echo -e "${org}\n${org,,}\n${org^^}" | sort -su); do
            vault_token="$(                                   \
                curl -s                                       \
                    -X POST                                   \
                    -H "Content-Type: application/json"       \
                    -d "{\"token\": \"$gh_token\"}"           \
                    "$VAULT_HOST/v1/auth/github-${org}/login" \
              | jq -r '.auth.client_token'                    \
            )";
            if [[ "${vault_token:-null}" != null ]]; then
                break;
            fi
        done
        if [[ "${vault_token:-null}" != null ]]; then
            break;
        fi
    done

    echo "vault_token='$vault_token'";
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(get_vault_token "$@");
