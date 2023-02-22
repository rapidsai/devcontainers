#! /usr/bin/env bash

export_sccache_vars() {

    local bucket="${SCCACHE_BUCKET:-$(grep 'bucket=' ~/.aws/config | sed 's/bucket=//')}";
    local region="${SCCACHE_REGION:-$(grep 'region=' ~/.aws/config | sed 's/region=//')}";

    if grep -q -E "^export SCCACHE_S3_NO_CREDENTIALS=true$" ~/.bashrc; then
        sed -i 's@export SCCACHE_S3_NO_CREDENTIALS=true@@g' ~/.bashrc;
    fi

    if ! grep -q -E "^export SCCACHE_BUCKET=${SCCACHE_BUCKET}$" ~/.bashrc; then
        echo "export SCCACHE_BUCKET=${SCCACHE_BUCKET}" >> ~/.bashrc;
    fi

    if ! grep -q -E "^export SCCACHE_REGION=${SCCACHE_REGION}$" ~/.bashrc; then
        echo "export SCCACHE_REGION=${SCCACHE_REGION}" >> ~/.bashrc;
    fi

    # If we succeeded at least once, install user crontab and refresh creds every 8hrs
    if ! crontab -l &> /dev/null; then
        crontab /opt/devcontainer/cron/vault-s3-init;
        sudo cron;
    fi
}

if [[ -f ~/.aws/stamp && -f ~/.aws/config && -f ~/.aws/credentials ]]; then
    export_sccache_vars;
elif ! grep -q -E "^export SCCACHE_S3_NO_CREDENTIALS=true$" ~/.bashrc; then
    echo "export SCCACHE_S3_NO_CREDENTIALS=true" >> ~/.bashrc;
fi

source ~/.bashrc;
