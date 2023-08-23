#! /usr/bin/env bash

# Attempt to retrieve temporary AWS credentials from a vault instance using GitHub OAuth.

generate_s3_creds() {

    set -euo pipefail;

    if test -z "${VAULT_HOST:-}" \
    || test -z "${SCCACHE_BUCKET:-}"; then
        return;
    fi

    SCCACHE_REGION="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}";

    # Remove existing credentials in case vault declines to issue new ones.
    rm -rf ~/.aws/{stamp,config,credentials};

    devcontainer-utils-vault-s3-creds-persist <<< "
        --bucket='${SCCACHE_BUCKET:-}'
        --region='${SCCACHE_REGION:-}'
    ";

    # Initialize the GitHub CLI with the appropriate user scopes
    source devcontainer-utils-init-github-cli;

    if test -z "${GITHUB_USER:-}"; then
        return;
    fi

    # Check whether the user is in one of the allowed GitHub orgs
    local allowed_orgs="${VAULT_GITHUB_ORGS:-nvidia nv-morpheus nv-legate rapids}";
    allowed_orgs="${allowed_orgs// /|}";
    allowed_orgs="${allowed_orgs//;/|}";
    allowed_orgs="${allowed_orgs//,/|}";

    local user_orgs="$(                              \
        gh api user/orgs --jq '.[].login'            \
            -H "Accept: application/vnd.github+json" \
        | grep --color=never -iE "(${allowed_orgs})" \
    )";

    if test -z "${user_orgs:-}"; then
        return;
    fi

    echo ""
    echo "Attempting to use your GitHub account to authenticate";
    echo "with vault at '${VAULT_HOST}'.";
    echo ""

    local vault_token="null";

    # Attempt to authenticate with GitHub
    eval "$(devcontainer-utils-vault-auth-github "${VAULT_HOST}" ${user_orgs})";

    if [ "${vault_token:-null}" = "null" ]; then
        echo "Your GitHub user was not recognized by vault. Skipping." >&2;
        return;
    fi

    echo "Successfully authenticated with vault!";

    local generated_at="$(date '+%s')";
    local ttl="${VAULT_S3_TTL:-"43200"}";
    local uri="${VAULT_S3_URI:-"v1/aws/creds/devs"}";

    if grep -qE '^[0-9]$' <<< "${ttl}"; then
        ttl+="s";
    fi

    # Generate temporary AWS creds
    local aws_creds="$(                         \
        curl -s                                 \
            -X GET                              \
            -H "X-Vault-Token: ${vault_token}"  \
            -H "Content-Type: application/json" \
            "${VAULT_HOST}/${uri}?ttl=${ttl}"   \
        | jq -r '.data'                         \
    )";

    local aws_access_key_id="$(jq -r '.access_key' <<< "${aws_creds}" || echo)";
    local aws_secret_access_key="$(jq -r '.secret_key' <<< "${aws_creds}" || echo)";

    if grep -qE "^null$" <<< "${aws_access_key_id:-null}"; then
        echo "Failed to retrieve AWS S3 credentials. Skipping." >&2;
        return;
    fi

    if grep -qE "^null$" <<< "${aws_secret_access_key:-null}"; then
        echo "Failed to retrieve AWS S3 credentials. Skipping." >&2;
        return;
    fi

    echo "Successfully generated temporary AWS S3 credentials!";

    # Block until the new temporary AWS S3 credentials propagate
    if  SCCACHE_BUCKET="${SCCACHE_BUCKET:-}" \
        SCCACHE_REGION="${SCCACHE_REGION:-}" \
        AWS_ACCESS_KEY_ID="${aws_access_key_id:-}"         \
        AWS_SECRET_ACCESS_KEY="${aws_secret_access_key:-}" \
        devcontainer-utils-vault-s3-creds-propagate; then
        # Store creds in ~/.aws dir
        devcontainer-utils-vault-s3-creds-persist <<< "
            --stamp='${generated_at:-}'
            --bucket='${SCCACHE_BUCKET:-}'
            --region='${SCCACHE_REGION:-}'
            --aws_access_key_id='${aws_access_key_id:-}'
            --aws_secret_access_key='${aws_secret_access_key:-}'
        ";
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(generate_s3_creds "$@");

. /etc/profile.d/*-devcontainer-utils.sh;
