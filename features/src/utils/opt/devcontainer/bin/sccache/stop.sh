#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-stop-sccache [OPTION]...
#
# Gracefully or forcefully stop the sccache server.
#
# Boolean options:
#  -h,--help      Print this text.
#  -k,--kill      SIGKILL the sccache server.
#  -a,--kill-all  SIGKILL all sccache processes.
#
# Options that require values:
#  -p,--port <port> Stop the sccache server on <port>.
#                   (default: ${SCCACHE_SERVER_PORT:-4226})
#

_stop_sccache() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache stop-sccache';

    if ! pgrep sccache >/dev/null 2>&1; then
        return 0;
    fi

    local sccache_port="${p:-${port:-${SCCACHE_SERVER_PORT:-4226}}}";
    local pidfile="/tmp/sccache.${sccache_port}.pid";

    if test -n "${a:-${kill_all:+x}}"; then
        # Shutdown all sccache processes forcefully
        pkill -9 sccache >/dev/null 2>&1 || true;
    elif test -n "${k:-${kill:+x}}" && test -f "${pidfile}"; then
        # Shutdown the sccache process on `$sccache_port` forcefully
        pkill -9 --pidfile "${pidfile}" >/dev/null 2>&1 || true;
    else
        # Shutdown gracefully
        SCCACHE_SERVER_PORT="${sccache_port}" \
        sccache --stop-server >/dev/null 2>&1 || true;
        if test -f "${pidfile}"; then
            # Wait for the server to shutdown
            if command -v pidwait >/dev/null 2>&1; then
                pidwait --pidfile "${pidfile}" >/dev/null 2>&1 || true;
            else
                while IFS= read -r pid; do
                    if test -n "${pid:+x}"; then
                        while test -e "/proc/${pid}"; do
                            sleep 0.1;
                        done
                    fi
                done < "${pidfile}"
            fi
        fi
    fi

    rm -f "${pidfile}" 2>/dev/null || true;
}

_stop_sccache "$@" <&0;
