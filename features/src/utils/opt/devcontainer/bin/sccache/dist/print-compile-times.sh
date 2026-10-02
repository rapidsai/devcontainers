#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-print-sccache-dist-compile-times [OPTION]...
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

_print_sccache_dist_compile_times() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache print-sccache-dist-compile-times';

    if ! pgrep sccache >/dev/null 2>&1; then
        return 0;
    fi

    local sccache_port="${p:-${port:-${SCCACHE_SERVER_PORT:-4226}}}";
    local logfile="${SCCACHE_ERROR_LOG:-/tmp/sccache.log}";

    logfile="$(dirname "$logfile")/$(basename -s .log "$logfile").${sccache_port}.log";

    join -1 3 -2 2 \
        <(grep 'Running job' "$logfile" |
          cut -d' ' -f1,4,5             |
          tr -d '[],'                   |
          sed -r 's/^(.*):$/\1/'        |
          sort -k3) \
        <(grep 'Fetched'     "$logfile" |
          cut -d' ' -f1,5 | tr -d '[],' |
          sort -k2) |
    awk '{
        gsub(/[-TZ:]/, " ", $2);
        gsub(/[-TZ:]/, " ", $4);
        print $3, (mktime($4) - mktime($2)) "s"
    }'
}

_print_sccache_dist_compile_times "$@" <&0;
