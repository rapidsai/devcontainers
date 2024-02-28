#! /usr/bin/env bash

# Attempt to retrieve temporary AWS credentials from a vault instance using GitHub OAuth.

generate_s3_creds() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'vault-s3 vault-s3-creds-generate';

    if test -z "${VAULT_HOST:-}" \
    || test -z "${SCCACHE_BUCKET:-}"; then
        exit 1;
    fi

    SCCACHE_REGION="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}";

    # Remove existing credentials in case vault declines to issue new ones.
    rm -rf ~/.aws/{stamp,config,credentials};

    devcontainer-utils-vault-s3-creds-persist - <<< \
        --bucket="${SCCACHE_BUCKET:-}"              \
        --region="${SCCACHE_REGION:-}"              ;

    # Initialize the GitHub CLI with the appropriate user scopes
    # shellcheck disable=SC1091
    . devcontainer-utils-init-github-cli;

    if test -z "${GITHUB_USER:-}"; then
        exit 1;
    fi

    # Check whether the user is in one of the allowed GitHub orgs
    local allowed_orgs="${VAULT_GITHUB_ORGS:-nvidia nv-morpheus nv-legate rapids}";
    allowed_orgs="${allowed_orgs// /|}";
    allowed_orgs="${allowed_orgs//;/|}";
    allowed_orgs="${allowed_orgs//,/|}";

    local -r user_orgs="$(                           \
        gh api user/orgs --jq '.[].login'            \
            -H "Accept: application/vnd.github+json" \
        | grep --color=never -iE "(${allowed_orgs})" \
    )";

    if test "${#user_orgs}" -eq 0; then
        exit 1;
    fi

    cat <<____EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log
$(date)
Attempting to use your GitHub account to authenticate with vault at:
'${VAULT_HOST}'.
____EOF

    local vault_token="null";

    # Attempt to authenticate with GitHub
    eval "$(devcontainer-utils-vault-auth-github "${VAULT_HOST}" "${user_orgs}")";

    if [ "${vault_token:-null}" = "null" ]; then
        cat <<________EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log >&2
Your GitHub user was not recognized by vault. Skipping.
________EOF
        exit 1;
    fi

    cat <<____EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log
Successfully authenticated with vault!
____EOF

    local -r generated_at="$(date '+%s')";
    local ttl="${VAULT_S3_TTL:-"28800"}";
    local uri="${VAULT_S3_URI:-"v1/aws/creds/devs"}";

    if grep -qE '^[0-9]$' <<< "${ttl}"; then
        ttl+="s";
    fi

    # Generate temporary AWS creds
    local -r aws_creds="$(                      \
        curl -s                                 \
            -X GET                              \
            -H "X-Vault-Token: ${vault_token}"  \
            -H "Content-Type: application/json" \
            "${VAULT_HOST}/${uri}?ttl=${ttl}"   \
        | jq -r '.data'                         \
    )";

    local -r aws_access_key_id="$(jq -r '.access_key' <<< "${aws_creds}" || echo)";
    local -r aws_secret_access_key="$(jq -r '.secret_key' <<< "${aws_creds}" || echo)";

    if grep -qE "^null$" <<< "${aws_access_key_id:-null}"; then
        cat <<________EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log >&2
Failed to retrieve AWS S3 credentials. Skipping.
________EOF
        exit 1;
    fi

    if grep -qE "^null$" <<< "${aws_secret_access_key:-null}"; then
        cat <<________EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log >&2
Failed to retrieve AWS S3 credentials. Skipping.
________EOF
        exit 1;
    fi

    cat <<____EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log
Successfully generated temporary AWS S3 credentials!
____EOF

    # Block until the new temporary AWS S3 credentials propagate
    if  SCCACHE_BUCKET="${SCCACHE_BUCKET:-}" \
        SCCACHE_REGION="${SCCACHE_REGION:-}" \
        AWS_ACCESS_KEY_ID="${aws_access_key_id:-}"         \
        AWS_SECRET_ACCESS_KEY="${aws_secret_access_key:-}" \
        devcontainer-utils-vault-s3-creds-propagate | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log; then
        # Store creds in ~/.aws dir
        devcontainer-utils-vault-s3-creds-persist - <<<         \
            --stamp="${generated_at:-}"                         \
            --bucket="${SCCACHE_BUCKET:-}"                      \
            --region="${SCCACHE_REGION:-}"                      \
            --aws-access-key-id="${aws_access_key_id:-}"        \
            --aws-secret-access-key="${aws_secret_access_key:-}";
    fi
}

generate_s3_creds "$@";

# shellcheck disable=SC1090
. /etc/profile.d/*-devcontainer-utils.sh;
