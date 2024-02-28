#! /usr/bin/env bash

schedule_s3_creds_refresh() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'vault-s3 vault-s3-creds-schedule';

    local -r now="$(date '+%s')";
    local ttl="${VAULT_S3_TTL:-"28800"}";
    ttl="${ttl%s}";

    local -r stamp="$(cat ~/.aws/stamp 2>/dev/null || echo "${now}")";
    local then="$((ttl - (now - stamp)))";
    then="$((then < ttl ? then : ttl))";
    then="$((((then + 59) / 60) * 60))";

    # Regenerate if within 5 minutes of keys expiring
    if test "${then}" -le 300; then
        if devcontainer-utils-vault-s3-creds-generate; then
            devcontainer-utils-vault-s3-creds-schedule;
        fi
    else
        # Regenerate 5 minutes before keys expire
        then="$((now + then - 300))";

        crontab -u "$(whoami)" -r 2>/dev/null || true;

        cat <<________EOF | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log
$(date --date="@${now}")
Scheduling cron to regerate S3 creds $(date -u --date="@$((then - now))" '+%T') from now.
________EOF

        cat <<________EOF | crontab -u "$(whoami)" -
SHELL=/bin/bash
BASH_ENV="${BASH_ENV:-}"
VAULT_HOST="${VAULT_HOST:-}"
GITHUB_USER="${GITHUB_USER:-}"
VAULT_S3_TTL="${VAULT_S3_TTL:-}"
SCCACHE_BUCKET="${SCCACHE_BUCKET:-}"
SCCACHE_REGION="${SCCACHE_REGION:-}"
VAULT_GITHUB_ORGS="${VAULT_GITHUB_ORGS:-}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-}"
$(date --date="@${then}" '+%M %H %d %m %w') \
devcontainer-utils-vault-s3-creds-schedule
________EOF

        sudo /etc/init.d/cron restart >/dev/null 2>&1;
    fi
}

schedule_s3_creds_refresh "$@";
