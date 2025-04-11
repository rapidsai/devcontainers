#! /usr/bin/env bash

_s3_cred() {
    sed -n "s/$1=//p" ~/.aws/credentials 2>/dev/null;
}

_s3_creds_init() {
    local -
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-init';

    if command -v sccache >/dev/null 2>&1; then
        if ! grep -qE "^$" <<< "${SCCACHE_BUCKET:-}"; then
            if grep -qE "^$" <<< "${AWS_ACCESS_KEY_ID:-}"     \
            && grep -qE "^$" <<< "${AWS_SECRET_ACCESS_KEY:-}" ; then
                if ! grep -qE "^$" <<< "${VAULT_HOST:-${AWS_ROLE_ARN:-}}"; then
                    # Generate S3 creds if they don't exist (or are expired)
                    if devcontainer-utils-creds-s3-test \
                    || devcontainer-utils-creds-s3-generate; then
                        # Persist creds in ~/.aws dir
                        devcontainer-utils-creds-s3-persist - <<< "                     \
                            --bucket '${SCCACHE_BUCKET:-}'                              \
                            --region '${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}'       \
                            --aws-access-key-id '$(_s3_cred aws_access_key_id)'         \
                            --aws-session-token '$(_s3_cred aws_session_token)'         \
                            --aws-secret-access-key '$(_s3_cred aws_secret_access_key)' \
                        ";
                        # Install a crontab to refresh the credentials
                        devcontainer-utils-creds-s3-schedule;
                    else
                        devcontainer-utils-creds-s3-persist - <<< "--no-bucket --no-region";
                    fi
                elif devcontainer-utils-creds-s3-test; then
                    devcontainer-utils-creds-s3-persist - <<< "                     \
                        --bucket '${SCCACHE_BUCKET:-}'                              \
                        --region '${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}'       \
                        --aws-access-key-id '$(_s3_cred aws_access_key_id)'         \
                        --aws-session-token '$(_s3_cred aws_session_token)'         \
                        --aws-secret-access-key '$(_s3_cred aws_secret_access_key)' \
                    ";
                else
                    # bucket is inaccessible
                    devcontainer-utils-creds-s3-persist - <<< "--no-bucket --no-region";
                fi
            elif ! devcontainer-utils-creds-s3-propagate; then
                # bucket is inaccessible
                devcontainer-utils-creds-s3-persist <<< "--no-bucket --no-region";
            fi
        fi
    fi
}

_s3_creds_init "$@";

# shellcheck disable=SC1090
. /etc/profile.d/*-devcontainer-utils.sh;
