#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-list-active-sccache-dist-compiles [OPTION]...
#
# Print all active sccache-dist compilations
#
# Boolean options:
#  -h,--help      Print this text.
#
# Options that require values:
#  -p,--port <port> Read the logfile for the sccache client running on <port>.
#                   (default: ${SCCACHE_SERVER_PORT:-4226})
#

_list_active_sccache_dist_compilations() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache list-active-sccache-dist-compiles';

    if ! pgrep sccache >/dev/null 2>&1; then
        return 0;
    fi

    local sccache_port="${p:-${port:-${SCCACHE_SERVER_PORT:-4226}}}";
    local logfile="${SCCACHE_ERROR_LOG:-/tmp/sccache.log}";

    logfile="$(dirname "$logfile")/$(basename -s .log "$logfile").${sccache_port}.log";

    cat                                 \
        <(grep 'Running job' "$logfile" \
        | cut -d[ -f3 | cut -d] -f1     \
        | tr -d ','                     \
        | sort -s                       \
        | uniq                          \
        )                               \
        <(grep 'Fetched' "$logfile"     \
        | cut -d[ -f3 | cut -d] -f1     \
        | cut -d, -f1,2                 \
        | tr -d ','                     \
        | sort -s                       \
        | uniq                          \
        )                               \
  | sort -s                             \
  | uniq -u
}

_list_active_sccache_dist_compilations "$@" <&0;
