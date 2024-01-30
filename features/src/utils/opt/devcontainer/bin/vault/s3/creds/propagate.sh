#! /usr/bin/env bash

ensure_s3_creds_have_propagated() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"vault-s3-creds-propagate"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    if ! type sccache >/dev/null 2>&1; then
        return;
    fi

    local num_restarts="0";

    if test -n "$(pgrep sccache || echo)"; then
        sccache --stop-server >/dev/null 2>&1 || true;
    fi

    while true; do

        if SCCACHE_NO_DAEMON=1 sccache --show-stats >/dev/null 2>&1; then
            if [ "${num_restarts}" -gt "0" ]; then echo "Success!"; fi
            exit 0;
        fi

        if [ "${num_restarts}" -ge "20" ]; then
            if [ "${num_restarts}" -gt "0" ]; then echo "Skipping."; fi
            exit 1;
        fi

        num_restarts="$((num_restarts + 1))";

        if [ "${num_restarts}" -eq "1" ]; then
            echo -n "Waiting for AWS S3 credentials to propagate... ";
        fi

        sleep 1;
    done
}

ensure_s3_creds_have_propagated "$@";
