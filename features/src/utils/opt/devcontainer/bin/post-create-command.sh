#!/usr/bin/env bash

set -e;

# Start crond if it isn't already started
if ! test -f /var/run/crond.pid; then
    cron 2>/dev/null || true;
fi

. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/update-envvars.sh";

# If SSH_AUTH_SOCK exists and isn't owned by the coder user, use socat to proxy
# between a socket owned by the coder user and the one mounted in from the host
if test -n "${SSH_AUTH_SOCK:-}" \
&& test "${SSH_AUTH_SOCK}" != ~/.ssh/socket \
&& test "$(stat -c "%u:%g" "${SSH_AUTH_SOCK}")" != "$(id -u):$(id -g)"; then
    # shellcheck disable=SC1091
    reset_envvar SSH_AUTH_SOCK;
    ssh_auth_sock=~/.ssh/socket;
    # If the remapped ssh socket doesn't already exist
    if ! test -f "${ssh_auth_sock}"; then
        # Map the host's ssh-agent socket to one owned by coder
        sudo --background socat "UNIX-LISTEN:${ssh_auth_sock},fork,user=$(id -nu),group=$(id -ng),mode=777" "UNIX-CONNECT:${SSH_AUTH_SOCK}";
        sleep 5;
    fi
    # test the remapped ssh-agent socket
    SSH_AUTH_SOCK="${ssh_auth_sock}" ssh-add -L 1>&2;
    # set SSH_AUTH_SOCK to the new remapped one
    export_envvar SSH_AUTH_SOCK "${ssh_auth_sock}";
    export SSH_AUTH_SOCK="${ssh_auth_sock}";
    unset ssh_auth_sock;
fi

# Randomize the sccache server port in case the container is launched with --network=host
if test -z "${SCCACHE_SERVER_PORT:-}"; then
    export_envvar SCCACHE_SERVER_PORT "$((4220 + $RANDOM % 4999))";
fi
