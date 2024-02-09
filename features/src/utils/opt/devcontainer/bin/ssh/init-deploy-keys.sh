#! /usr/bin/env bash

init_ssh_deploy_keys() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${devcontainer_utils_debug##*"init-deploy-keys"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    local re="(ssh:\/\/|https:\/\/)?(git@)?(.*\.com)[:\/](.*)";
    local line;

    # shellcheck disable=SC2155
    ssh-add -L | while read -r line; do
        local key="$(cut -d' ' -f2 <<< "${line}")";
        local url="$(cut -d' ' -f3 <<< "${line}")";
        local sha="$(md5sum --tag <<< "${key}" | cut -d' ' -f4)";

        if [[ ${url} =~ ${re} ]]; then

            local host="${BASH_REMATCH[3]}";
            local repo="${BASH_REMATCH[4]//.git/}";
            local file="$HOME/.ssh/key-${sha}.pub";

            if ! test -f "${file}"; then
                cat <<________________EOF | tee -a "${file}" >/dev/null
${line}
________________EOF
            fi

            cat <<____________EOF | tee -a ~/.gitconfig >/dev/null
[url "git@key-${sha}.${host}:${repo}"]
  insteadOf = https://${host}/${repo}
  insteadOf = git@${host}:${repo}
  insteadOf = ssh://git@${host}/${repo}
____________EOF

            cat <<____________EOF | tee -a ~/.ssh/config >/dev/null
Host key-${sha}.${host}
    HostName ${host}
    IdentityFile ${file}
    IdentitiesOnly yes
____________EOF

        fi
    done

    chmod 0700 ~/.ssh;
    chmod 0600 ~/.ssh/*;
}

init_ssh_deploy_keys "$@";
