#! /usr/bin/env bash

_creds_github_generate() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-vault creds-s3-vault-generate';

    if test -z "${AWS_ROLE_ARN:-}" \
    || test -z "${SCCACHE_BUCKET:-}" \
    || ! gh nv-gha-aws --help >/dev/null 2>&1; then
        exit 1;
    fi

    # Remove existing credentials in case nv-gha-aws declines to issue new ones.
    if test -w ~/.aws; then
        rm -rf ~/.aws/{stamp,config,credentials};
    fi

    SCCACHE_REGION="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}";

    devcontainer-utils-creds-s3-persist - <<< \
        --bucket="${SCCACHE_BUCKET:-}"        \
        --region="${SCCACHE_REGION:-}"        ;

    # Initialize the GitHub CLI with the appropriate user scopes
    # shellcheck disable=SC1091
    . devcontainer-utils-init-github-cli;

    # Check whether the user is in one of the allowed GitHub orgs
    local allowed_orgs="${AWS_GITHUB_ORGS:-${VAULT_GITHUB_ORGS:-nvidia nv-morpheus nv-legate rapids}}";
    allowed_orgs="${allowed_orgs// /|}";
    allowed_orgs="${allowed_orgs//;/|}";
    allowed_orgs="${allowed_orgs//,/|}";

    local -ra user_orgs="($(                         \
        gh api user/orgs --jq '.[].login'            \
            -H "Accept: application/vnd.github+json" \
        | grep --color=never -iE "(${allowed_orgs})" \
    ))";

    if test "${#user_orgs[@]}" -eq 0; then
        exit 1;
    fi

    local org;
    local generated_at;
    local -a nv_gha_aws_args=(
        --profile default
        --output creds-file
        --role-arn "${AWS_ROLE_ARN}"
        --aud "${AWS_AUDIENCE:-sts.amazonaws.com}"
        --duration "${AWS_S3_TTL:-${VAULT_S3_TTL:-43200}}"
        --idp-url "${AWS_IDP_URL:-https://token.gha-runners.nvidia.com}"
    );

    sudo mkdir -m 0775 -p /var/log/devcontainer-utils;
    sudo touch /var/log/devcontainer-utils/creds-s3.log;
    sudo chmod 0664 /var/log/devcontainer-utils/creds-s3.log;
    sudo chgrp crontab /var/log/devcontainer-utils/creds-s3.log;

    for org in "${user_orgs[@]}"; do
        generated_at="$(date '+%s')";
        if gh nv-gha-aws org "${org}" "${nv_gha_aws_args[@]}" >"${HOME}/.aws/credentials" 2>>/var/log/devcontainer-utils/creds-s3.log; then
            if devcontainer-utils-creds-s3-propagate 2>&1 | tee -a /var/log/devcontainer-utils/creds-s3.log; then
                if test -w ~/.aws; then
                    echo "${generated_at}" > ~/.aws/stamp;
                fi
                return 0;
            fi
        fi
    done

    exit 1;
}

_creds_github_generate "$@" <&0;
