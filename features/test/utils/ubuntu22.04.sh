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
    export SCCACHE_BUCKET=;
    export SCCACHE_REGION=;
    export AWS_ACCESS_KEY_ID=;
    export AWS_SESSION_TOKEN=;
    export AWS_SECRET_ACCESS_KEY=;

    export -n GH_TOKEN;
    export -n VAULT_HOST;
    export -n SCCACHE_BUCKET;
    export -n SCCACHE_REGION;
    export -n AWS_ACCESS_KEY_ID;
    export -n AWS_SESSION_TOKEN;
    export -n AWS_SECRET_ACCESS_KEY;

    unset GH_TOKEN;
    unset VAULT_HOST;
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
    sccache --show-stats | grep "Cache location";
    sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ s3';
}

expect_local_disk_cache_is_used() {
    sccache --show-stats | grep "Cache location";
    sccache --show-stats 2>&1 | grep -qE 'Cache location \s+ Local disk';
}

if test -n "${vault_host:-}" \
&& test -n "${rw_sccache_bucket:-}"; then

    vault_host_with_no_bucket_uses_local_disk_cache() {
        reset_state;
        VAULT_HOST="${vault_host}" \
        devcontainer-utils-post-attach-command;
        expect_local_disk_cache_is_used;
    }

    check "VAULT_HOST with no SCCACHE_BUCKET uses local disk cache" vault_host_with_no_bucket_uses_local_disk_cache;
fi

if test -n "${rw_sccache_bucket:-}"; then

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

# Disabled until sccache v0.5.4 is released (see https://github.com/mozilla/sccache/issues/1799)
# if test -n "${ro_sccache_bucket:-}"; then

#     readonly_sccache_bucket_uses_s3_cache() {
#         reset_state;
#         SCCACHE_BUCKET="${ro_sccache_bucket}" \
#         SCCACHE_REGION="${ro_sccache_region}" \
#         devcontainer-utils-post-attach-command;
#         expect_s3_cache_is_used;
#     }

#     check "Readonly SCCACHE_BUCKET uses S3 cache" readonly_sccache_bucket_uses_s3_cache;
# fi

if test -n "${gh_token:-}" \
&& test -n "${vault_host:-}" \
&& test -n "${rw_sccache_bucket:-}"; then

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
        export AWS_ACCESS_KEY_ID="$(grep 'aws_access_key_id=' /tmp/.aws/credentials 2>/dev/null | sed 's/aws_access_key_id=//' || echo)";
        export AWS_SESSION_TOKEN="$(grep 'aws_session_token=' /tmp/.aws/credentials 2>/dev/null | sed 's/aws_session_token=//' || echo)";
        export AWS_SECRET_ACCESS_KEY="$(grep 'aws_secret_access_key=' /tmp/.aws/credentials 2>/dev/null | sed 's/aws_secret_access_key=//' || echo)";
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

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
