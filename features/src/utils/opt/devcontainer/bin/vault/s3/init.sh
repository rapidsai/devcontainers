#! /usr/bin/env bash

vault_s3_init() {

    set -euo pipefail;

    # Attempt to retrieve temporary AWS credentials from a vault
    # instance using GitHub OAuth.

    if [ -z "${VAULT_HOST:-}" ] || [ -z "${SCCACHE_BUCKET:-}" ]; then
        return;
    fi

    # Initialize the GitHub CLI with the appropriate user scopes
    eval "export $(devcontainer-utils-init-github-cli)";

    if [[ -z "${GITHUB_USER:-}" ]]; then
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
      | grep --color=never -E "(${allowed_orgs})"    \
    )";

    if [[ -z "${user_orgs:-}" ]]; then
        return;
    fi

    # Remove existing credentials in case vault declines to issue new ones.
    rm -rf ~/.aws/{stamp,config,credentials};

    echo ""
    echo "Attempting to use your GitHub account to authenticate";
    echo "with vault at '${VAULT_HOST}'.";
    echo ""

    local vault_token=null;

    # Attempt to authenticate with GitHub
    eval "$(devcontainer-utils-vault-auth-github "${VAULT_HOST}" ${user_orgs})";

    if [[ "${vault_token:-null}" == null ]]; then
        echo "Your GitHub user was not recognized by vault. Skipping." >&2;
        return;
    fi

    echo "Successfully authenticated with vault!";

    local ttl="${VAULT_S3_TTL:-"43200s"}";
    local uri="${VAULT_S3_URI:-"v1/aws/creds/devs"}";

    # Generate temporary AWS creds
    local aws_creds="$(                         \
        curl -s                                 \
            -X GET                              \
            -H "X-Vault-Token: $vault_token"    \
            -H "Content-Type: application/json" \
            "${VAULT_HOST}/$uri?ttl=$ttl"       \
      | jq -r '.data'                           \
    )";

    local aws_access_key_id="$(echo "$aws_creds" | jq -r '.access_key')";
    local aws_secret_access_key="$(echo "$aws_creds" | jq -r '.secret_key')";

    if [[ "${aws_access_key_id:-null}" == null ]]; then
        echo "Failed to generate temporary AWS S3 credentials. Skipping." >&2;
        return;
    fi

    if [[ "${aws_secret_access_key:-null}" == null ]]; then
        echo "Failed to generate temporary AWS S3 credentials. Skipping." >&2;
        return;
    fi

    # Generate AWS config files
    mkdir -p ~/.aws;

    echo "$(date '+%s')" > ~/.aws/stamp;

    cat <<EOF > ~/.aws/config
[default]
${SCCACHE_BUCKET:+bucket=$SCCACHE_BUCKET}
${SCCACHE_REGION:+region=$SCCACHE_REGION}
EOF

    cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=$aws_access_key_id
aws_secret_access_key=$aws_secret_access_key
EOF

    chmod 0600 ~/.aws/{config,credentials};

    echo "Successfully generated temporary AWS S3 credentials!";
}

(vault_s3_init "$@");

if [ -n "${VAULT_HOST:-}" ] && [ -n "${SCCACHE_BUCKET:-}" ]; then
    __s3_checks__="0";
    __s3_status__="1";
    while true; do
        __s3_status__="$(devcontainer-utils-vault-s3-test >/dev/null 2>&1; echo $?)";
        if [ "${__s3_status__}" -ne "1" ]; then
            if [ "${__s3_checks__}" -gt "0" ]; then echo "Success!"; fi
            break;
        fi
        if [ "${__s3_checks__}" -ge "20" ]; then
            if [ "${__s3_checks__}" -gt "0" ]; then echo "Skipping."; fi
            break;
        fi
        __s3_checks__="$((__s3_checks__ + 1))";
        if [ "${__s3_checks__}" -eq "1" ]; then
            echo -n "Waiting for AWS S3 credentials to propagate... ";
        fi
        sleep 1;
    done
    . devcontainer-utils-vault-s3-export "${__s3_status__}";
    unset __s3_checks__;
    unset __s3_status__;
fi
