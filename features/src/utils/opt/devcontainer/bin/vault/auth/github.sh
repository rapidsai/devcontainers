#! /usr/bin/env bash

set -euo pipefail;

get_vault_token() {

    local VAULT_HOST="$1";
    local user_orgs="${@:2}";
    local gh_token="$(gh auth token)";
    local org

    local vault_token=null;

    for org in ${user_orgs}; do
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

    echo "vault_token='$vault_token'";
}

get_vault_token "$@";
