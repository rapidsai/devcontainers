#! /usr/bin/env bash

# Test sccache AWS S3 credentials are valid

test_aws_creds() {

    set -euo pipefail;

    if ! type sccache >/dev/null 2>&1; then exit 1; fi;

    if [ -f ~/.aws/stamp ]; then
        if [ $(($(date '+%s') - $(cat ~/.aws/stamp))) -gt $((3600 * 8)) ]; then
            exit 1;
        fi
    fi

    local bucket="$(grep 'bucket=' ~/.aws/config 2>/dev/null | sed 's/bucket=//' || echo "${SCCACHE_BUCKET:-}")";
    if [ -z "${bucket:-}" ]; then exit 1; fi

    local region="$(grep 'region=' ~/.aws/config 2>/dev/null | sed 's/region=//' || echo "${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}")";
    local aws_access_key_id="$(grep 'aws_access_key_id=' ~/.aws/credentials 2>/dev/null | sed 's/aws_access_key_id=//' || echo "${AWS_ACCESS_KEY_ID:-}")";
    local aws_secret_access_key="$(grep 'aws_secret_access_key=' ~/.aws/credentials 2>/dev/null | sed 's/aws_secret_access_key=//' || echo "${AWS_SECRET_ACCESS_KEY:-}")";

    sccache --stop-server >/dev/null 2>&1 || true;

    if ! \
       SCCACHE_NO_DAEMON=1 \
       AWS_ACCESS_KEY_ID=${aws_access_key_id} \
       AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
       SCCACHE_BUCKET=${bucket} SCCACHE_REGION=${region} \
       sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ s3'; then
        if SCCACHE_NO_DAEMON=1 \
           SCCACHE_S3_NO_CREDENTIALS=1 \
           AWS_ACCESS_KEY_ID=${aws_access_key_id} \
           AWS_SECRET_ACCESS_KEY=${aws_secret_access_key} \
           SCCACHE_BUCKET=${bucket} SCCACHE_REGION=${region} \
           sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ s3'; then
            exit 2;
        fi
        exit 1;
    fi
    exit 0;
}

(test_aws_creds "$@");
