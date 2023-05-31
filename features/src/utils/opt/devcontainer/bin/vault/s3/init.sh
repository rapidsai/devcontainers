#! /usr/bin/env bash

vault_s3_init() {

    set -euo pipefail;

    if [ -z "${SCCACHE_BUCKET:-}" ]; then
        return;
    fi

    local aws_access_key_id="${AWS_ACCESS_KEY_ID:-}";
    local aws_secret_access_key="${AWS_SECRET_ACCESS_KEY:-}";

    # Remove existing credentials in case vault declines to issue new ones.
    rm -rf ~/.aws/{stamp,config,credentials};

    if  [ -n "${VAULT_HOST:-}" ]; then

        # Attempt to retrieve temporary AWS credentials from a vault
        # instance using GitHub OAuth.

        # Initialize the GitHub CLI with the appropriate user scopes
        source devcontainer-utils-init-github-cli;

        if [ -n "${GITHUB_USER:-}" ]; then

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

            if [ -z "${user_orgs:-}" ]; then
                return;
            fi

            echo ""
            echo "Attempting to use your GitHub account to authenticate";
            echo "with vault at '${VAULT_HOST}'.";
            echo ""

            local vault_token=null;

            # Attempt to authenticate with GitHub
            eval "$(devcontainer-utils-vault-auth-github "${VAULT_HOST}" ${user_orgs})";

            if [ "${vault_token:-null}" = "null" ]; then
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

            aws_access_key_id="$(echo "${aws_creds}" | jq -r '.access_key')";
            aws_secret_access_key="$(echo "${aws_creds}" | jq -r '.secret_key')";

            if [ "${aws_access_key_id:-null}" = "null" ]; then
                echo "Failed to retrieve AWS S3 credentials. Skipping." >&2;
                return;
            fi

            if [ "${aws_secret_access_key:-null}" = "null" ]; then
                echo "Failed to retrieve AWS S3 credentials. Skipping." >&2;
                return;
            fi
        fi
    fi

    if [ "${aws_access_key_id:-null}" = "null" ]; then
        return;
    fi

    if [ "${aws_secret_access_key:-null}" = "null" ]; then
        return;
    fi

    # Generate AWS config files
    mkdir -p ~/.aws;

    echo "$(date '+%s')" > ~/.aws/stamp;

    SCCACHE_REGION="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}";

    cat <<EOF > ~/.aws/config
[default]
${SCCACHE_BUCKET:+"bucket=${SCCACHE_BUCKET}"}
${SCCACHE_REGION:+"region=${SCCACHE_REGION}"}
EOF

    cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=${aws_access_key_id}
aws_secret_access_key=${aws_secret_access_key}
EOF

    chmod 0600 ~/.aws/{config,credentials};

    echo "Successfully generated temporary AWS S3 credentials!";

    SCCACHE_BUCKET="${SCCACHE_BUCKET}" \
    SCCACHE_REGION="${SCCACHE_REGION}" \
    AWS_ACCESS_KEY_ID="${aws_access_key_id}" \
    AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}" \
        devcontainer-utils-vault-s3-export 0;
}

vault_s3_wait() {

    set -euo pipefail;

    local cache_status="";
    local num_restarts="0";

    if type sccache >/dev/null 2>&1 \
    && [ -n "${VAULT_HOST:-}" ] \
    && [ -n "${SCCACHE_BUCKET:-}" ]; then
        sccache --stop-server >/dev/null 2>&1 || true;
        while true; do
            if SCCACHE_NO_DAEMON=1 sccache --show-stats >/dev/null 2>&1; then
                if [ "${num_restarts}" -gt "0" ]; then echo "Success!"; fi
                sccache --start-server >/dev/null 2>&1 || true;
                cache_status="0";
                break;
            fi
            if [ "${num_restarts}" -ge "20" ]; then
                if [ "${num_restarts}" -gt "0" ]; then echo "Skipping."; fi
                sccache --start-server >/dev/null 2>&1 || true;
                cache_status="1";
                break;
            fi
            num_restarts="$((num_restarts + 1))";
            if [ "${num_restarts}" -eq "1" ]; then
                echo -n "Waiting for AWS S3 credentials to propagate... ";
            fi
            sleep 1;
        done
    fi

    devcontainer-utils-vault-s3-export "${cache_status}";
}

(vault_s3_init "$@");

. /etc/profile.d/*-devcontainer-utils.sh;

(vault_s3_wait "$@");

. /etc/profile.d/*-devcontainer-utils.sh;
