#! /usr/bin/env bash

export_envvar() {
    if [ -n "${1:-}" ]; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            echo "export ${1}=\"${2:-}\";" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

unset_envvar() {
    if [ -n "${1:-}" ]; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            echo "unset ${1};" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

reset_envvar() {
    if [ -n "${1:-}" ]; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            if grep -q -E "^unset ${1};\$" "${file}"; then
                sudo sed -Ei "/^unset ${1};\$/d" "${file}";
            fi
            if grep -q -E "^export ${1}=.*$" "${file}"; then
                sudo sed -Ei "/^export ${1}=.*\$/d" "${file}";
            fi
        done
    fi
}

store_s3_creds() {

    set -euo pipefail;

    local stamp=;
    local bucket=;
    local region=;
    local no_bucket=;
    local no_region=;
    local no_credentials=;
    local aws_access_key_id=;
    local aws_session_token=;
    local aws_secret_access_key=;

    eval "$(                                  \
        devcontainer-utils-parse-args --names "
            stamp                             |
            bucket                            |
            region                            |
            no_bucket                         |
            no_region                         |
            no_credentials                    |
            aws_access_key_id                 |
            aws_session_token                 |
            aws_secret_access_key"            \
            - <&0                             \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    # Reset envvars
    reset_envvar "SCCACHE_BUCKET";
    reset_envvar "SCCACHE_REGION";
    reset_envvar "AWS_ACCESS_KEY_ID";
    reset_envvar "AWS_SESSION_TOKEN";
    reset_envvar "AWS_SECRET_ACCESS_KEY";
    reset_envvar "SCCACHE_S3_NO_CREDENTIALS";

    mkdir -p ~/.aws;
    rm -f ~/.aws/{config,credentials};

    if test -n "${stamp:-}"; then
        echo "${stamp:-}" > ~/.aws/stamp;
    fi

    if ! grep -qE "^$" <<< "${no_bucket:-}"; then
        unset_envvar "SCCACHE_BUCKET";
    elif ! grep -qE "^$" <<< "${bucket:-}"; then
        export_envvar "SCCACHE_BUCKET" "${bucket}";
        cat <<________EOF >> ~/.aws/config
bucket=${bucket:-}
________EOF
    fi

    if ! grep -qE "^$" <<< "${no_region:-}"; then
        unset_envvar "SCCACHE_REGION";
    elif ! grep -qE "^$" <<< "${region:-}"; then
        export_envvar "SCCACHE_REGION" "${region}";
        cat <<________EOF >> ~/.aws/config
region=${region:-}
________EOF
    fi

    if test -f ~/.aws/config; then
        cat <<________EOF > ~/.aws/config
[default]
$(cat ~/.aws/config)
________EOF
    fi

    if ! grep -qE "^$" <<< "${no_credentials:-}"; then
        export_envvar "SCCACHE_S3_NO_CREDENTIALS" "1";
    else

        if ! grep -qE "^$" <<< "${aws_access_key_id:-}"; then
            cat <<____________EOF >> ~/.aws/credentials
aws_access_key_id=${aws_access_key_id}
____________EOF
        fi

        if ! grep -qE "^$" <<< "${aws_session_token:-}"; then
            cat <<____________EOF >> ~/.aws/credentials
aws_session_token=${aws_session_token}
____________EOF
        fi

        if ! grep -qE "^$" <<< "${aws_secret_access_key:-}"; then
            cat <<____________EOF >> ~/.aws/credentials
aws_secret_access_key=${aws_secret_access_key}
____________EOF
        fi

        if test -f ~/.aws/credentials; then
            cat <<____________EOF > ~/.aws/credentials
[default]
$(cat ~/.aws/credentials)
____________EOF
            chmod 0600 ~/.aws/credentials;
        fi
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(store_s3_creds "$@");
