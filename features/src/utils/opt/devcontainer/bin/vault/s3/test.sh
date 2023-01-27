#! /usr/bin/env bash

set -euo pipefail;

# Test AWS S3 credentials are still valid the same way sccache does

test_aws_creds() {
    if [[ ! -f ~/.aws/config ]]; then exit 1; fi;
    if [[ ! -f ~/.aws/credentials ]]; then exit 1; fi;

    local region="$(grep 'region=' ~/.aws/config | sed 's/region=//')";
    if [[ -z ${region:-} ]]; then exit 1; fi;

    local bucket="$(grep 'bucket=' ~/.aws/config | sed 's/bucket=//')";
    if [[ -z ${bucket:-} ]]; then exit 1; fi;

    local aws_session_token="$(grep 'aws_session_token=' ~/.aws/credentials | sed 's/aws_session_token=//')";

    local aws_access_key_id="$(grep 'aws_access_key_id=' ~/.aws/credentials | sed 's/aws_access_key_id=//')";
    if [[ -z ${aws_access_key_id:-} ]]; then exit 1; fi;

    local aws_secret_access_key="$(grep 'aws_secret_access_key=' ~/.aws/credentials | sed 's/aws_secret_access_key=//')";
    if [[ -z ${aws_access_key_id:-} ]]; then exit 1; fi;

    # Test GET
    AWS_SESSION_TOKEN="$aws_session_token" \
    AWS_ACCESS_KEY_ID="$aws_access_key_id" \
    AWS_SECRET_ACCESS_KEY="$aws_secret_access_key" \
    aws-curl -s -X GET --region "${region}" -o /tmp/.sccache_check \
        "https://${bucket}.s3.amazonaws.com/.sccache_check";

    # Test PUT
    AWS_SESSION_TOKEN="$aws_session_token" \
    AWS_ACCESS_KEY_ID="$aws_access_key_id" \
    AWS_SECRET_ACCESS_KEY="$aws_secret_access_key" \
    aws-curl -s -X PUT --region "${region}" -d @/tmp/.sccache_check \
        "https://${bucket}.s3.amazonaws.com/.sccache_check";
}

test_aws_creds
