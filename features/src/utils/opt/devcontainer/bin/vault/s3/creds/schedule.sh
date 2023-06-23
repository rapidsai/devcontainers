#! /usr/bin/env bash

schedule_s3_creds_refresh() {

    set -euo pipefail;

    local now="$(date '+%s')";
    local ttl="${VAULT_S3_TTL:-"43200s"}";
    ttl="${ttl%s}";

    crontab -u $(whoami) -r 2>/dev/null || true;

    if [ -f ~/.aws/stamp ]; then
        local stamp="$(cat ~/.aws/stamp)";
        if [ $((now - stamp)) -le ${ttl} ]; then
            local when="$((now + (ttl - (now - stamp)) - 1))";
            local expr="$(date --date="@${when}" '+%M %H %d %m %w')";
            cat <<________EOF | crontab -u $(whoami) -
SHELL=/bin/bash
BASH_ENV=/etc/bash.bash_env
${expr} source \$BASH_ENV && (eval devcontainer-utils-vault-s3-creds-{generate\ \&\&,schedule}) 2>&1 | tee -a /var/log/devcontainer-utils-vault-s3-creds-refresh.log
________EOF
        fi
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(schedule_s3_creds_refresh "$@");
