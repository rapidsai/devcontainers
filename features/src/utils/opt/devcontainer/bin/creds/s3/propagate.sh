#! /usr/bin/env bash

_creds_s3_propagate() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-propagate';

    if ! command -V sccache >/dev/null 2>&1; then
        return;
    fi

    local num_restarts="0";

    devcontainer-utils-stop-sccache --kill-all;

    while true; do

        if devcontainer-utils-start-sccache >/dev/null; then
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

_creds_s3_propagate "$@";
