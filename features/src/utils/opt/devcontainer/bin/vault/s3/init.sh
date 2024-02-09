#! /usr/bin/env bash

s3_cred() {
    grep "$1=" ~/.aws/credentials 2>/dev/null | sed "s/$1=//" || echo;
}

init_vault_s3_creds() {

    local -
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${devcontainer_utils_debug##*"vault-s3"*}" \
      || test -z "${devcontainer_utils_debug##*"vault-s3-init"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    if type sccache >/dev/null 2>&1; then
        if test -n "${SCCACHE_BUCKET:-}"; then
            if grep -qE "^$" <<< "${AWS_ACCESS_KEY_ID:-}"     \
            && grep -qE "^$" <<< "${AWS_SECRET_ACCESS_KEY:-}" ; then
                if test -n "${VAULT_HOST:-}"                  ; then
                    # Generate S3 creds if they don't exist (or are expired)
                    if devcontainer-utils-vault-s3-creds-test \
                    || devcontainer-utils-vault-s3-creds-generate; then
                        # Persist creds in ~/.aws dir
                        devcontainer-utils-vault-s3-creds-persist - <<<               \
                            --bucket="${SCCACHE_BUCKET:-}"                            \
                            --region="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}"     \
                            --aws-access-key-id="$(s3_cred aws_access_key_id)"        \
                            --aws-session-token="$(s3_cred aws_session_token)"        \
                            --aws-secret-access-key="$(s3_cred aws_secret_access_key)";
                        # Install a crontab to refresh the credentials
                        devcontainer-utils-vault-s3-creds-schedule;
                    else
                        devcontainer-utils-vault-s3-creds-persist - <<< --no-bucket --no-region;
                    fi
                elif devcontainer-utils-vault-s3-creds-test; then
                    devcontainer-utils-vault-s3-creds-persist - <<<               \
                        --bucket="${SCCACHE_BUCKET:-}"                            \
                        --region="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}"     \
                        --aws-access-key-id="$(s3_cred aws_access_key_id)"        \
                        --aws-session-token="$(s3_cred aws_session_token)"        \
                        --aws-secret-access-key="$(s3_cred aws_secret_access_key)";
                else
                    # bucket is inaccessible
                    devcontainer-utils-vault-s3-creds-persist - <<< --no-bucket --no-region;
                fi
            else
                # Block until the new temporary AWS S3 credentials propagate
                devcontainer-utils-vault-s3-creds-propagate;
            fi
        fi
        # shellcheck disable=SC1090
        . /etc/profile.d/*-devcontainer-utils.sh;
        # start the sccache server
        sccache --start-server || true;
    fi
}

init_vault_s3_creds "$@";

# shellcheck disable=SC1090
. /etc/profile.d/*-devcontainer-utils.sh;
