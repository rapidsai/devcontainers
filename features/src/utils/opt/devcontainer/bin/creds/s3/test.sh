#! /usr/bin/env bash

# Test sccache AWS S3 credentials are valid

_creds_s3_test() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-test';

    if ! command -V sccache >/dev/null 2>&1; then
        return 1;
    fi

    if test -f ~/.aws/stamp; then
        local -r now="$(date '+%s')";
        local -r stamp="$(cat ~/.aws/stamp)";
        local ttl="${VAULT_S3_TTL:-"43200"}";
        if [ $((now - stamp)) -ge "${ttl%s}" ]; then
            return 1;
        fi
    fi

    local bucket="${SCCACHE_BUCKET:-"$(sed -n 's/bucket=//p' ~/.aws/config 2>/dev/null)"}";
    if ! test -n "${bucket:+n}"; then
        return 1;
    fi

    local region="${SCCACHE_REGION:-"${AWS_DEFAULT_REGION:-"$(sed -n 's/region=//p' ~/.aws/config 2>/dev/null)"}"}";
    local aws_access_key_id="${AWS_ACCESS_KEY_ID:-"$(sed -n 's/aws_access_key_id=//p' ~/.aws/credentials 2>/dev/null)"}";
    local aws_session_token="${AWS_SESSION_TOKEN:-"$(sed -n 's/aws_session_token=//p' ~/.aws/credentials 2>/dev/null)"}";
    local aws_secret_access_key="${AWS_SECRET_ACCESS_KEY:-"$(sed -n 's/aws_secret_access_key=//p' ~/.aws/credentials 2>/dev/null)"}";

    devcontainer-utils-stop-sccache --kill -p 4220 || true;

    local result=0;

    if ! AWS_PROFILE=none                                        \
         SCCACHE_BUCKET="${bucket:-}"                            \
         SCCACHE_REGION="${region:-}"                            \
         AWS_ACCESS_KEY_ID="${aws_access_key_id:-}"              \
         AWS_SESSION_TOKEN="${aws_session_token:-}"              \
         AWS_SECRET_ACCESS_KEY="${aws_secret_access_key:-}"      \
         timeout --preserve-status --kill-after=1m 30s           \
         devcontainer-utils-start-sccache -p 4220 >/dev/null 2>&1; then
       result=1;
    elif ! SCCACHE_SERVER_PORT=4220 sccache --show-stats 2>/dev/null \
         | grep -qE 'Cache location \s+ s3'; then
       result=1;
    fi

    devcontainer-utils-stop-sccache --kill -p 4220 || true;

    if test "$result" -eq 0; then
        local logfile="${SCCACHE_ERROR_LOG:-/tmp/sccache.log}";
        logfile="$(dirname "$logfile")/$(basename -s .log "$logfile").4220.log";
        rm -f "${logfile}";
    fi

    return "$result";
}

_creds_s3_test "$@";
