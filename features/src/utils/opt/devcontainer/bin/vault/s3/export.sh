#! /usr/bin/env bash

append_envvar() {
    if [ -n "${1:-}" ]; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            echo "export ${1}=\"${2:-}\";" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

remove_envvar() {
    if [ -n "${1:-}" ]; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            if grep -q -E "^export ${1}=.*$" "${file}"; then
                sudo sed -Ei "/^export ${1}=.*\$/d" "${file}";
            fi
        done
    fi
}

test_s3_creds_and_update_envvars() {

    set -euo pipefail;

    remove_envvar "SCCACHE_BUCKET";
    remove_envvar "SCCACHE_REGION";
    remove_envvar "AWS_ACCESS_KEY_ID";
    remove_envvar "AWS_SECRET_ACCESS_KEY";
    remove_envvar "SCCACHE_S3_NO_CREDENTIALS";

    for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
        sudo sed -Ei '/^unset AWS_SECRET_ACCESS_KEY;$/d' "${file}";
        sudo sed -Ei '/^unset AWS_ACCESS_KEY_ID;$/d' "${file}";
        sudo sed -Ei '/^unset SCCACHE_BUCKET;$/d' "${file}";
        sudo sed -Ei '/^unset SCCACHE_REGION;$/d' "${file}";
    done

    local s3_status="${1:-$(devcontainer-utils-vault-s3-test >/dev/null 2>&1; echo $?)}";

    local bucket="$(grep 'bucket=' ~/.aws/config 2>/dev/null | sed 's/bucket=//' || echo "${SCCACHE_BUCKET:-}")";
    local region="$(grep 'region=' ~/.aws/config 2>/dev/null | sed 's/region=//' || echo "${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}")";
    local aws_access_key_id="$(grep 'aws_access_key_id=' ~/.aws/credentials 2>/dev/null | sed 's/aws_access_key_id=//' || echo "${AWS_ACCESS_KEY_ID:-}")";
    local aws_secret_access_key="$(grep 'aws_secret_access_key=' ~/.aws/credentials 2>/dev/null | sed 's/aws_secret_access_key=//' || echo "${AWS_SECRET_ACCESS_KEY:-}")";

    case $s3_status in
        [0] ) # bucket is read + write
            append_envvar "AWS_SECRET_ACCESS_KEY" "${aws_secret_access_key}";
            append_envvar "AWS_ACCESS_KEY_ID" "${aws_access_key_id}";
            append_envvar "SCCACHE_BUCKET" "${bucket}";
            append_envvar "SCCACHE_REGION" "${region}";
            # install a crontab to refresh creds
            if ! crontab -l >/dev/null 2>&1; then
                crontab -u $(whoami) /opt/devcontainer/cron/vault-s3-init;
                sudo cron;
            fi
            ;;
        [2] ) # bucket is read-only
            append_envvar "AWS_SECRET_ACCESS_KEY" "${aws_secret_access_key}";
            append_envvar "AWS_ACCESS_KEY_ID" "${aws_access_key_id}";
            append_envvar "SCCACHE_S3_NO_CREDENTIALS" "1";
            append_envvar "SCCACHE_BUCKET" "${bucket}";
            append_envvar "SCCACHE_REGION" "${region}";
            ;;
          * ) # bucket is inaccessible
            for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
                echo "unset AWS_SECRET_ACCESS_KEY;" | sudo tee -a "${file}" >/dev/null;
                echo "unset AWS_ACCESS_KEY_ID;" | sudo tee -a "${file}" >/dev/null;
                echo "unset SCCACHE_BUCKET;" | sudo tee -a "${file}" >/dev/null;
                echo "unset SCCACHE_REGION;" | sudo tee -a "${file}" >/dev/null;
            done
            ;;
    esac
}

(test_s3_creds_and_update_envvars "$@");

. /etc/profile.d/*-devcontainer-utils.sh;
