#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-start-sccache [OPTION]...
#
# Start the sccache server in the foreground or background.
#
# Boolean options:
#  -f,--foreground Start the sccache server in the foreground.
#  -h,--help       Print this text.
#  -k,--kill      SIGKILL the existing sccache server on the given port.
#  -a,--kill-all  SIGKILL all sccache processes.
#
# Options that require values:
#  -p,--port <port> Start the sccache server on <port>.
#                   If there is already a server listening
#                   on this port, it will be killed first.
#                   (default: ${SCCACHE_SERVER_PORT:-4226})
#

_start_sccache() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache start-sccache';

    local sccache_port="${p:-${port:-${SCCACHE_SERVER_PORT:-4226}}}";
    local pidfile="/tmp/sccache.${sccache_port}.pid";

    # Stop any existing server
    devcontainer-utils-stop-sccache "$@";

    local logfile="${SCCACHE_ERROR_LOG:-/tmp/sccache.log}";
    local log_lvl="${SCCACHE_LOG:-${SCCACHE_SERVER_LOG-}}";

    logfile="$(dirname "$logfile")/$(basename -s .log "$logfile").${sccache_port}.log";

    if test -n "${f:-${foreground:+x}}"; then
        # Unset this so sccache outputs to stderr
        unset SCCACHE_ERROR_LOG;
        # Start the sccache server in the foreground
        RUST_LOG_STYLE="always"                                 \
        SCCACHE_NO_DAEMON=1                                     \
        SCCACHE_START_SERVER=1                                  \
        SCCACHE_SERVER_LOG="${log_lvl}"                         \
        SCCACHE_SERVER_PORT="${sccache_port}"                   \
        sccache 2>&1                                            \
      | tee >(cat <(echo "=== sccache logfile: $logfile ===")   \
                  <(cat - )                                     \
                  >&2)                                          \
            >(sed -u 's/\x1B\[[0-9;]*[JKmsu]//g' >"$logfile")   \
            >/dev/null                                          ;
    else
        # Start the sccache server in the background
        RUST_LOG_STYLE="never"                  \
        SCCACHE_ERROR_LOG="${logfile}"          \
        SCCACHE_SERVER_LOG="${log_lvl}"         \
        SCCACHE_SERVER_PORT="${sccache_port}"   \
        sccache --start-server 1>&2 2>/dev/null \
      | tee "$logfile";
        # Write the pid to the pidfile
        pgrep sccache | sort -nr | head -n1 | tee "${pidfile}" >/dev/null;
        echo "=== sccache logfile: $logfile ===" >&2;
        echo "=== sccache pidfile: $pidfile ===" >&2;
    fi
}

_start_sccache "$@" <&0;
