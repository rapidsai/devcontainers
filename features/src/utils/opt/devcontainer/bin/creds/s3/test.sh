#! /usr/bin/env bash

# Test sccache AWS S3 credentials are valid

_creds_s3_test() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-test';

    if ! type sccache >/dev/null 2>&1; then exit 1; fi

    if test -f ~/.aws/stamp; then
        local -r now="$(date '+%s')";
        local -r stamp="$(cat ~/.aws/stamp)";
        local ttl="${VAULT_S3_TTL:-"43200"}";
        if [ $((now - stamp)) -ge "${ttl%s}" ]; then
            exit 1;
        fi
    fi

    local bucket="${SCCACHE_BUCKET:-"$(sed -n 's/bucket=//p' ~/.aws/config 2>/dev/null)"}";
    if [ -z "${bucket:-}" ]; then exit 1; fi

    local region="${SCCACHE_REGION:-"${AWS_DEFAULT_REGION:-"$(sed -n 's/region=//p' ~/.aws/config 2>/dev/null)"}"}";
    local aws_access_key_id="${AWS_ACCESS_KEY_ID:-"$(sed -n 's/aws_access_key_id=//p' ~/.aws/credentials 2>/dev/null)"}";
    local aws_session_token="${AWS_SESSION_TOKEN:-"$(sed -n 's/aws_session_token=//p' ~/.aws/credentials 2>/dev/null)"}";
    local aws_secret_access_key="${AWS_SECRET_ACCESS_KEY:-"$(sed -n 's/aws_secret_access_key=//p' ~/.aws/credentials 2>/dev/null)"}";

    if test -n "$(pgrep sccache || echo)"; then
        sccache --stop-server >/dev/null 2>&1 || true;
    fi

    SCCACHE_BUCKET="${bucket:-}" \
    SCCACHE_REGION="${region:-}" \
    AWS_ACCESS_KEY_ID="${aws_access_key_id:-}" \
    AWS_SESSION_TOKEN="${aws_session_token:-}" \
    AWS_SECRET_ACCESS_KEY="${aws_secret_access_key:-}" \
    sccache --start-server >/dev/null 2>&1;
    sccache --show-stats | grep -qE 'Cache location \s+ s3';
}

_creds_s3_test "$@";
