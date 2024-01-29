#! /usr/bin/env bash

s3_cred() {
    grep "$1=" ~/.aws/credentials 2>/dev/null | sed "s/$1=//" || echo;
}

init_vault_s3_creds() {

    local -
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"vault-s3-init"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    if type sccache >/dev/null; then
        if test -n "${SCCACHE_BUCKET:-}"; then
            if grep -qE "^$" <<< "${AWS_ACCESS_KEY_ID:-}"     \
            && grep -qE "^$" <<< "${AWS_SECRET_ACCESS_KEY:-}" ; then
                if test -n "${VAULT_HOST:-}"                  ; then
                    # Generate S3 creds if they don't exist (or are expired)
                    if devcontainer-utils-vault-s3-creds-test >/dev/null 2>&1 \
                    || devcontainer-utils-vault-s3-creds-generate; then
                        # Persist creds in ~/.aws dir
                        devcontainer-utils-vault-s3-creds-persist - <<<               \
                            --bucket="${SCCACHE_BUCKET:-}"                            \
                            --region="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}"     \
                            --aws-access-key-id="$(s3_cred aws_access_key_id)"        \
                            --aws-session-token="$(s3_cred aws_session_token)"        \
                            --aws-secret-access-key="$(s3_cred aws_secret_access_key)";
                        # Install a crontab to refresh the credentials
                        devcontainer-utils-vault-s3-creds-schedule;
                    else
                        devcontainer-utils-vault-s3-creds-persist - <<< --no-bucket --no-region;
                    fi
                else
                    # If credentials have been mounted in, ensure they're used
                    case $(devcontainer-utils-vault-s3-creds-test; echo $?) in
                        # bucket is read + write with the current credentials
                        [0] )
                            devcontainer-utils-vault-s3-creds-persist - <<<               \
                                --bucket="${SCCACHE_BUCKET:-}"                            \
                                --region="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}"     \
                                --aws-access-key-id="$(s3_cred aws_access_key_id)"        \
                                --aws-session-token="$(s3_cred aws_session_token)"        \
                                --aws-secret-access-key="$(s3_cred aws_secret_access_key)";
                            ;;
                        # bucket is read-only and should be accessed without credentials
                        [2] )
                            devcontainer-utils-vault-s3-creds-persist - <<<          \
                                --no-credentials                                     \
                                --bucket="${SCCACHE_BUCKET:-}"                       \
                                --region="${SCCACHE_REGION:-${AWS_DEFAULT_REGION:-}}";
                            ;;
                          # bucket is inaccessible
                          * )
                            devcontainer-utils-vault-s3-creds-persist - <<< --no-bucket --no-region;;
                    esac
                fi
            elif devcontainer-utils-vault-s3-creds-propagate; then
                # Block until the new temporary AWS S3 credentials propagate
                echo -n "";
            fi
        fi
        # shellcheck disable=SC1090
        . /etc/profile.d/*-devcontainer-utils.sh;
        # start the sccache server
        sccache --start-server >/dev/null 2>&1 || true;
    fi
}

init_vault_s3_creds "$@";

# shellcheck disable=SC1090
. /etc/profile.d/*-devcontainer-utils.sh;
