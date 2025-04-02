#! /usr/bin/env bash

_creds_s3_schedule() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-schedule';

    local -r now="$(date '+%s')";
    local ttl="${VAULT_S3_TTL:-"43200"}";
    ttl="${ttl%s}";

    local -r stamp="$(cat ~/.aws/stamp 2>/dev/null || echo "${now}")";
    local ttime="$((ttl - (now - stamp)))";
    ttime="$((ttime < ttl ? ttime : ttl))";
    ttime="$((( (ttime + 59) / 60) * 60))";

    # Regenerate creds if within `min(ttl / 5, 2hrs)` of keys expiring
    local refresh_window="$(((ttl / 5) > 7200 ? 7200 : ttl / 5))";

    if test "${ttime}" -le "${refresh_window}"; then
        if devcontainer-utils-creds-s3-generate; then
            devcontainer-utils-creds-s3-schedule;
        fi
    else
        ttime="$((now + ttime - refresh_window))";

        crontab -u "$(whoami)" -r 2>/dev/null || true;

        cat <<________EOF | tee -a /var/log/devcontainer-utils/creds-s3.log
$(date --date="@${now}")
Scheduling cron to regerate S3 creds $(date -u --date="@$((ttime - now))" '+%T') from now.
________EOF

        cat <<________EOF | crontab -u "$(whoami)" -
SHELL=/bin/bash
BASH_ENV="${BASH_ENV:-}"
VAULT_HOST="${VAULT_HOST:-}"
GITHUB_USER="${GITHUB_USER:-}"
AWS_S3_TTL="${AWS_S3_TTL:-}"
AWS_IDP_URL="${AWS_IDP_URL:-}"
AWS_ROLE_ARN="${AWS_ROLE_ARN:-}"
AWS_AUDIENCE="${AWS_AUDIENCE:-}"
AWS_GITHUB_ORGS="${AWS_GITHUB_ORGS:-}"
VAULT_S3_TTL="${VAULT_S3_TTL:-}"
SCCACHE_BUCKET="${SCCACHE_BUCKET:-}"
SCCACHE_REGION="${SCCACHE_REGION:-}"
VAULT_GITHUB_ORGS="${VAULT_GITHUB_ORGS:-}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-}"
$(date --date="@${ttime}" '+%M %H %d %m %w') \
devcontainer-utils-creds-s3-schedule
________EOF

        sudo /etc/init.d/cron restart >>/var/log/devcontainer-utils/creds-s3.log 2>&1;
    fi
}

_creds_s3_schedule "$@";
