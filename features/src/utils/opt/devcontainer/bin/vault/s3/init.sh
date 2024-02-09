#! /usr/bin/env bash

s3_bucket_args() {
    cat <<____EOF
        --bucket='${SCCACHE_BUCKET:-}'
        --region='${SCCACHE_REGION:-"${AWS_DEFAULT_REGION:-}"}'
____EOF
}

s3_bucket_auth() {
    cat <<____EOF
        --aws_access_key_id='$(sed -n 's/aws_access_key_id=//p' ~/.aws/credentials 2>/dev/null)'
        --aws_session_token='$(sed -n 's/aws_session_token=//p' ~/.aws/credentials 2>/dev/null)'
        --aws_secret_access_key='$(sed -n 's/aws_secret_access_key=//p' ~/.aws/credentials 2>/dev/null)'
____EOF
}

init_vault_s3_creds() {

    set -euo pipefail;

    if type sccache >/dev/null; then
        if test -n "${SCCACHE_BUCKET:-}"; then
            if grep -qE "^$" <<< "${AWS_ACCESS_KEY_ID:-}"     \
            && grep -qE "^$" <<< "${AWS_SECRET_ACCESS_KEY:-}" ; then
                if test -n "${VAULT_HOST:-}"                  ; then
                    # Generate S3 creds if they don't exist (or are expired)
                    if devcontainer-utils-vault-s3-creds-test \
                    || devcontainer-utils-vault-s3-creds-generate; then
                        # Persist creds in ~/.aws dir
                        devcontainer-utils-vault-s3-creds-persist <<< "
                            $(s3_bucket_args)
                            $(s3_bucket_auth)
                        ";
                        # Install a crontab to refresh the credentials
                        devcontainer-utils-vault-s3-creds-schedule;
                    else
                        devcontainer-utils-vault-s3-creds-persist <<< "--no_bucket --no_region";
                    fi
                elif devcontainer-utils-vault-s3-creds-test; then
                    # bucket is read + write with the current credentials
                    devcontainer-utils-vault-s3-creds-persist <<< "
                        $(s3_bucket_args)
                        $(s3_bucket_auth)
                    ";
                else
                    # bucket is inaccessible
                    devcontainer-utils-vault-s3-creds-persist <<< "--no_bucket --no_region";
                fi
            elif ! devcontainer-utils-vault-s3-creds-propagate; then
                # bucket is inaccessible
                devcontainer-utils-vault-s3-creds-persist <<< "--no_bucket --no_region";
            fi
        fi
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(init_vault_s3_creds "$@");

. /etc/profile.d/*-devcontainer-utils.sh;
