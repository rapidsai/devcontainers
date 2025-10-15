#! /usr/bin/env bash

_creds_s3_propagate() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'creds-s3 creds-s3-propagate';

    if ! command -V sccache >/dev/null 2>&1; then
        return 1;
    fi

    seq 0 20 | while read -r num_restarts; do
        if devcontainer-utils-creds-s3-test; then
            if test "$num_restarts" -gt 0; then
                echo "Success!";
            fi
            return 0;
        fi

        if test "$num_restarts" -ge 20; then
            if test "$num_restarts" -gt 0; then
                echo "Skipping.";
            fi
            return 1;
        fi

        if test "$num_restarts" -eq 0; then
            echo -n "Waiting for AWS S3 credentials to propagate... ";
        fi

        sleep 1;
    done
}

_creds_s3_propagate "$@";
