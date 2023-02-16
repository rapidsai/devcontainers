#! /usr/bin/env bash

export_sccache_vars() {

    local bucket="${SCCACHE_BUCKET:-}";
    local region="${SCCACHE_REGION:-}";
    local usessl="${SCCACHE_S3_USE_SSL:-}";

    if [ -f  ~/.aws/config ]; then
        bucket="${bucket:-$(grep "bucket=" ~/.aws/config | sed 's/bucket=//')}";
        region="${region:-$(grep "region=" ~/.aws/config | sed 's/region=//')}";
    fi

    if [ -f  ~/.aws/credentials ]; then
        region="${region:-$(grep "region=" ~/.aws/credentials | sed 's/region=//')}";
    fi

    if [[ -z "${bucket:-}" || -z "${region:-}" ]]; then
        exit 0;
    fi

    export SCCACHE_S3_USE_SSL="${usessl:-true}";
    export SCCACHE_BUCKET="${bucket:-rapids-sccache-devs}";
    export SCCACHE_REGION="${region:-us-east-2}";

    if ! grep -q -E "^export SCCACHE_S3_USE_SSL=${SCCACHE_S3_USE_SSL}$" ~/.bashrc; then
        echo "export SCCACHE_S3_USE_SSL=${SCCACHE_S3_USE_SSL}" >> ~/.bashrc;
    fi

    if ! grep -q -E "^export SCCACHE_BUCKET=${SCCACHE_BUCKET}$" ~/.bashrc; then
        echo "export SCCACHE_BUCKET=${SCCACHE_BUCKET}" >> ~/.bashrc;
    fi

    if ! grep -q -E "^export SCCACHE_REGION=${SCCACHE_REGION}$" ~/.bashrc; then
        echo "export SCCACHE_REGION=${SCCACHE_REGION}" >> ~/.bashrc;
    fi
}

export_sccache_vars "$@";
