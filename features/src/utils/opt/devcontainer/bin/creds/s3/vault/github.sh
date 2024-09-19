#! /usr/bin/env bash

_creds_vault_auth_github() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-vault creds-s3-vault-auth-github';

    local -r VAULT_HOST="$1";
    local -r user_orgs=("${@:2}");
    local -r gh_token="$(gh auth token)";
    local vault_token=null;
    local o;
    local org;

    for o in "${user_orgs[@]}"; do
        for org in $(echo -e "${o}\n${o,,}\n${o^^}" | sort -su); do
            vault_token="$(                                     \
                curl -s                                         \
                    -X POST                                     \
                    -H "Content-Type: application/json"         \
                    -d "{\"token\": \"${gh_token}\"}"           \
                    "${VAULT_HOST}/v1/auth/github-${org}/login" \
              | jq -r '.auth.client_token'                      \
            )";
            if test "${vault_token:-null}" != null; then
                break;
            fi
        done
        if test "${vault_token:-null}" != null; then
            break;
        fi
    done

    echo "vault_token='$vault_token'";
}

_creds_vault_auth_github "$@";
