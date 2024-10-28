#! /usr/bin/env bash

_creds_s3_generate() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-generate';

    if test -z "${SCCACHE_BUCKET:-}"; then
        exit 1;
    fi

    if test -n "${AWS_ROLE_ARN:-}" && gh nv-gha-aws --help >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        devcontainer-utils-creds-s3-gh-generate;
    elif test -n "${VAULT_HOST:-}"; then
        # shellcheck disable=SC1091
        devcontainer-utils-creds-s3-vault-generate;
    fi
}

_creds_s3_generate "$@" <&0;
