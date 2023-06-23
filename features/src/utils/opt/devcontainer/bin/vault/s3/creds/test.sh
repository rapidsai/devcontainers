#! /usr/bin/env bash

# Test sccache AWS S3 credentials are valid

test_aws_creds() {

    set -euo pipefail;

    if ! type sccache >/dev/null 2>&1; then exit 1; fi

    if test -f ~/.aws/stamp; then
        local now="$(date '+%s')";
        local stamp="$(cat ~/.aws/stamp)";
        local ttl="${VAULT_S3_TTL:-"43200s"}";
        if [ $((now - stamp)) -ge "${ttl%s}" ]; then
            exit 1;
        fi
    fi

    local bucket="${SCCACHE_BUCKET:-"$(grep 'bucket=' ~/.aws/config 2>/dev/null | sed 's/bucket=//' || echo)"}";
    if [ -z "${bucket:-}" ]; then exit 1; fi

    local region="${SCCACHE_REGION:-"${AWS_DEFAULT_REGION:-"$(grep 'region=' ~/.aws/config 2>/dev/null | sed 's/region=//' || echo)"}"}";
    local aws_access_key_id="${AWS_ACCESS_KEY_ID:-"$(grep 'aws_access_key_id=' ~/.aws/credentials 2>/dev/null | sed 's/aws_access_key_id=//' || echo)"}";
    local aws_session_token="${AWS_SESSION_TOKEN:-"$(grep 'aws_session_token=' ~/.aws/credentials 2>/dev/null | sed 's/aws_session_token=//' || echo)"}";
    local aws_secret_access_key="${AWS_SECRET_ACCESS_KEY:-"$(grep 'aws_secret_access_key=' ~/.aws/credentials 2>/dev/null | sed 's/aws_secret_access_key=//' || echo)"}";

    sccache --stop-server >/dev/null 2>&1 || true;

    if ! \
       SCCACHE_NO_DAEMON=1 \
       SCCACHE_BUCKET="${bucket:-}" \
       SCCACHE_REGION="${region:-}" \
       AWS_ACCESS_KEY_ID="${aws_access_key_id:-}" \
       AWS_SESSION_TOKEN="${aws_session_token:-}" \
       AWS_SECRET_ACCESS_KEY="${aws_secret_access_key:-}" \
       sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ s3'; then
        # Disabled until sccache v0.5.4 is released (see https://github.com/mozilla/sccache/issues/1799)
        # if SCCACHE_NO_DAEMON=1 \
        #    SCCACHE_BUCKET="${bucket:-}" \
        #    SCCACHE_REGION="${region:-}" \
        #    SCCACHE_S3_NO_CREDENTIALS="1" \
        #    sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ s3'; then
        #     sccache --start-server >/dev/null 2>&1 || true;
        #     exit 2;
        # fi

        sccache --start-server >/dev/null 2>&1 || true;
        exit 1;
    fi

    exit 0;
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(test_aws_creds "$@");
