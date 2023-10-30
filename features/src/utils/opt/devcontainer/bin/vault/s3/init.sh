#! /usr/bin/env bash

s3_bucket_args() {
    cat <<____EOF
        --bucket='${SCCACHE_BUCKET:-}'
        --region='${SCCACHE_REGION:-"${AWS_DEFAULT_REGION:-}"}'
____EOF
}

s3_bucket_auth() {
    cat <<____EOF
        --aws_access_key_id='$(grep 'aws_access_key_id=' ~/.aws/credentials 2>/dev/null | sed 's/aws_access_key_id=//' || echo)'
        --aws_session_token='$(grep 'aws_session_token=' ~/.aws/credentials 2>/dev/null | sed 's/aws_session_token=//' || echo)'
        --aws_secret_access_key='$(grep 'aws_secret_access_key=' ~/.aws/credentials 2>/dev/null | sed 's/aws_secret_access_key=//' || echo)'
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
                    if devcontainer-utils-vault-s3-creds-test 2>&1 >/dev/null\
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
                else
                    # If credentials have been mounted in, ensure they're used
                    case $(devcontainer-utils-vault-s3-creds-test; echo $?) in
                        # bucket is read + write with the current credentials
                        [0] )
                            devcontainer-utils-vault-s3-creds-persist <<< "
                                $(s3_bucket_args)
                                $(s3_bucket_auth)
                            ";;
                        # bucket is read-only and should be accessed without credentials
                        [2] )
                            devcontainer-utils-vault-s3-creds-persist <<< "
                                --no_credentials
                                $(s3_bucket_args)
                            ";;
                          # bucket is inaccessible
                          * )
                            devcontainer-utils-vault-s3-creds-persist <<< "--no_bucket --no_region";;
                    esac
                fi
            elif devcontainer-utils-vault-s3-creds-propagate; then
                # Block until the new temporary AWS S3 credentials propagate
                echo -n "";
            fi
        fi
        . /etc/profile.d/*-devcontainer-utils.sh;
        # start the sccache server
        sccache --start-server >/dev/null 2>&1 || true;
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(init_vault_s3_creds "$@");

. /etc/profile.d/*-devcontainer-utils.sh;
