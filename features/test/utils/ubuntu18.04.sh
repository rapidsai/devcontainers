#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cuda \
#     --base-image ubuntu:22.04 .'
# ```

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.

export VAULT_S3_TTL="${VAULT_S3_TTL:-"900"}";

cp ~/.bashrc /tmp/.bashrc-clean;

utils_profile_script="$(find /etc/profile.d/ -type f -name '*-devcontainer-utils.sh')";

reset_state() {
    export GH_TOKEN=;
    export VAULT_HOST=;
    export AWS_ROLE_ARN=;
    export SCCACHE_BUCKET=;
    export SCCACHE_REGION=;
    export AWS_ACCESS_KEY_ID=;
    export AWS_SESSION_TOKEN=;
    export AWS_SECRET_ACCESS_KEY=;

    export -n GH_TOKEN;
    export -n VAULT_HOST;
    export -n AWS_ROLE_ARN;
    export -n SCCACHE_BUCKET;
    export -n SCCACHE_REGION;
    export -n AWS_ACCESS_KEY_ID;
    export -n AWS_SESSION_TOKEN;
    export -n AWS_SECRET_ACCESS_KEY;

    unset GH_TOKEN;
    unset VAULT_HOST;
    unset AWS_ROLE_ARN;
    unset SCCACHE_BUCKET;
    unset SCCACHE_REGION;
    unset AWS_ACCESS_KEY_ID;
    unset AWS_SESSION_TOKEN;
    unset AWS_SECRET_ACCESS_KEY;

    rm -rf ~/.aws/ ~/.config/gh/;
    cp /tmp/.bashrc-clean ~/.bashrc;
    echo "#! /usr/bin/env bash" | sudo tee "${utils_profile_script}" >/dev/null;
    sudo chmod +x "${utils_profile_script}";
    . ~/.bashrc;

    if test -n "$(pgrep sccache || echo)"; then
        sccache --stop-server >/dev/null 2>&1 || true;
    fi
}

write_bad_creds() {
    devcontainer-utils-vault-s3-creds-persist <<< "
        --stamp='$(date '+%s')'
        --bucket='${rw_sccache_bucket:-}'
        --region='${rw_sccache_region:-}'
        --aws_access_key_id='bad_aws_access_key_id'
        --aws_session_token='bad_aws_session_token'
        --aws_secret_access_key='bad_aws_secret_access_key'
    ";
}

expect_s3_cache_is_used() {
    local stats="$(sccache --show-stats 2>&1)";
    grep "Cache location" <<< "${stats}";
    grep -qE 'Cache location \s+ s3' <<< "${stats}";
}

expect_local_disk_cache_is_used() {
    local stats="$(sccache --show-stats 2>&1)";
    grep "Cache location" <<< "${stats}";
    grep -qE 'Cache location \s+ Local disk' <<< "${stats}";
}

if test -n "${vault_host:+x}" \
&& test -n "${rw_sccache_bucket:+x}"; then

    vault_host_with_no_bucket_uses_local_disk_cache() {
        reset_state;
        VAULT_HOST="${vault_host}" \
        devcontainer-utils-post-attach-command;
        expect_local_disk_cache_is_used;
    }

    check "VAULT_HOST with no SCCACHE_BUCKET uses local disk cache" vault_host_with_no_bucket_uses_local_disk_cache;
fi

if test -n "${rw_sccache_bucket:+x}"; then

    no_creds_with_bucket_uses_local_disk_cache() {
        reset_state;
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_local_disk_cache_is_used;
    }

    check "no creds with SCCACHE_BUCKET uses local disk cache" no_creds_with_bucket_uses_local_disk_cache;

    bad_creds_with_no_bucket_and_no_vault_host_uses_local_disk_cache() {
        reset_state;
        write_bad_creds;
        devcontainer-utils-post-attach-command;
        expect_local_disk_cache_is_used;
    }

    check "bad creds with no SCCACHE_BUCKET and no VAULT_HOST uses local disk cache" bad_creds_with_no_bucket_and_no_vault_host_uses_local_disk_cache;

    bad_creds_with_sccache_bucket_and_no_vault_host_uses_local_disk_cache() {
        reset_state;
        write_bad_creds;
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_local_disk_cache_is_used;
    }

    check "bad creds with SCCACHE_BUCKET and no VAULT_HOST uses local disk cache" bad_creds_with_sccache_bucket_and_no_vault_host_uses_local_disk_cache;
fi

if test -n "${gh_token:+x}" \
&& test -n "${vault_host:+x}" \
&& test -n "${rw_sccache_bucket:+x}"; then

    no_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_generate_credentials() {
        reset_state;
        GH_TOKEN="${gh_token}" \
        VAULT_HOST="${vault_host}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "no creds with GH_TOKEN, VAULT_HOST, and SCCACHE_BUCKET should generate credentials" no_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_generate_credentials;

    existing_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_reuse_credentials() {
        rm -rf /tmp/.aws;
        mv ~/.aws /tmp/;
        reset_state;
        cp -ar /tmp/.aws ~/;
        GH_TOKEN="${gh_token}" \
        VAULT_HOST="${vault_host}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "existing creds with GH_TOKEN, VAULT_HOST, and SCCACHE_BUCKET should reuse credentials" existing_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_reuse_credentials;

    should_use_provided_AWS_envvar_credentials() {
        reset_state;
        export SCCACHE_BUCKET="${rw_sccache_bucket}";
        export SCCACHE_REGION="${rw_sccache_region}";
        export AWS_ACCESS_KEY_ID="$(sed -n 's/aws_access_key_id=//p' /tmp/.aws/credentials 2>/dev/null)";
        export AWS_SESSION_TOKEN="$(sed -n 's/aws_session_token=//p' /tmp/.aws/credentials 2>/dev/null)";
        export AWS_SECRET_ACCESS_KEY="$(sed -n 's/aws_secret_access_key=//p' /tmp/.aws/credentials 2>/dev/null)";
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "should use provided AWS envvar credentials" should_use_provided_AWS_envvar_credentials;

    bad_stored_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_regenerate_credentials() {
        reset_state;
        write_bad_creds;
        GH_TOKEN="${gh_token}" \
        VAULT_HOST="${vault_host}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "bad stored creds with GH_TOKEN, VAULT_HOST, and SCCACHE_BUCKET should regenerate credentials" bad_stored_creds_with_GH_TOKEN_VAULT_HOST_and_SCCACHE_BUCKET_should_regenerate_credentials;
fi

if test -n "${gh_token:+x}" \
&& test -n "${aws_role_arn:+x}" \
&& test -n "${rw_sccache_bucket:+x}"; then

    no_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_generate_credentials() {
        reset_state;
        GH_TOKEN="${gh_token}" \
        AWS_ROLE_ARN="${aws_role_arn}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "no creds with GH_TOKEN, AWS_ROLE_ARN, and SCCACHE_BUCKET should generate credentials" no_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_generate_credentials;

    existing_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_reuse_credentials() {
        rm -rf /tmp/.aws;
        mv ~/.aws /tmp/;
        reset_state;
        cp -ar /tmp/.aws ~/;
        GH_TOKEN="${gh_token}" \
        AWS_ROLE_ARN="${aws_role_arn}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "existing creds with GH_TOKEN, AWS_ROLE_ARN, and SCCACHE_BUCKET should reuse credentials" existing_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_reuse_credentials;

    should_use_provided_AWS_envvar_credentials() {
        reset_state;
        export SCCACHE_BUCKET="${rw_sccache_bucket}";
        export SCCACHE_REGION="${rw_sccache_region}";
        export AWS_ACCESS_KEY_ID="$(sed -n 's/aws_access_key_id=//p' /tmp/.aws/credentials 2>/dev/null)";
        export AWS_SESSION_TOKEN="$(sed -n 's/aws_session_token=//p' /tmp/.aws/credentials 2>/dev/null)";
        export AWS_SECRET_ACCESS_KEY="$(sed -n 's/aws_secret_access_key=//p' /tmp/.aws/credentials 2>/dev/null)";
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "should use provided AWS envvar credentials" should_use_provided_AWS_envvar_credentials;

    bad_stored_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_regenerate_credentials() {
        reset_state;
        write_bad_creds;
        GH_TOKEN="${gh_token}" \
        AWS_ROLE_ARN="${aws_role_arn}" \
        SCCACHE_BUCKET="${rw_sccache_bucket}" \
        SCCACHE_REGION="${rw_sccache_region}" \
        devcontainer-utils-post-attach-command;
        expect_s3_cache_is_used;
    }

    check "bad stored creds with GH_TOKEN, AWS_ROLE_ARN, and SCCACHE_BUCKET should regenerate credentials" bad_stored_creds_with_GH_TOKEN_AWS_ROLE_ARN_and_SCCACHE_BUCKET_should_regenerate_credentials;
fi

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
