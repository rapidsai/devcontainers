#! /usr/bin/env bash

vault_s3_init() {

    set -euo pipefail;

    # Attempt to retrieve temporary AWS credentials from a vault
    # instance using GitHub OAuth.

    if [[ -z "${VAULT_HOST:-}" ]]; then
        devcontainer-utils-vault-s3-export 1;
        return;
    fi
    if [[ -z "${SCCACHE_BUCKET:-}" ]]; then
        devcontainer-utils-vault-s3-export 1;
        return;
    fi

    # Initialize the GitHub CLI with the appropriate user scopes
    eval "export $(devcontainer-utils-init-github-cli)";

    if [[ -z "${GITHUB_USER:-}" ]]; then
        devcontainer-utils-vault-s3-export 1;
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
        devcontainer-utils-vault-s3-export 1;
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
        devcontainer-utils-vault-s3-export 1;
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
        devcontainer-utils-vault-s3-export 1;
        return;
    fi

    if [[ "${aws_secret_access_key:-null}" == null ]]; then
        echo "Failed to generate temporary AWS S3 credentials. Skipping." >&2;
        devcontainer-utils-vault-s3-export 1;
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

    devcontainer-utils-vault-s3-export 0;

    echo "Successfully generated temporary AWS S3 credentials!";
}

(vault_s3_init "$@");

. ~/.bashrc;

if type sccache >/dev/null 2>&1 && test -n "${SCCACHE_BUCKET}"; then (
    __sccache_starts__=0;
    while test 1; do
        sccache --stop-server >/dev/null 2>&1 || true;
        if SCCACHE_NO_DAEMON=1 sccache --show-stats >/dev/null 2>&1; then
            if test "${__sccache_starts__}" -gt "0"; then
                echo "Success!";
            fi
            break;
        if test "${__sccache_starts__}" -gt "19"; then
            echo "Skipping.";
            break;
        fi
        __sccache_starts__="$((__sccache_starts__ + 1))";
        if test "${__sccache_starts__}" -eq "1"; then
            echo -n "Waiting for AWS S3 credentials to propagate... ";
        fi
        sleep 1;
    done;
    unset __sccache_starts__;
)
fi
