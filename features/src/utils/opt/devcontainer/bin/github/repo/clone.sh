#! /usr/bin/env bash

set -euo pipefail;

clone_github_repo() {

    . /opt/devcontainer/bin/github/cli/init.sh;
    if [[ -z "$GITHUB_USER" ]]; then exit 1; fi

    local user="$GITHUB_USER";
    local orig="${1:?orig is required}"; shift;
    local repo="${1:?repo is required}"; shift;
    local dest="${1:-$repo}";
    if test -n "${1:-}"; then shift; fi;
    local args="${@}";
    local fork="$(gh repo list $user --fork --json name             \
        --jq ". | map(select(.name == \"${repo}\")) | map(.name)[]")";

    if [[ -z "$fork" ]]; then

        local src="${orig}/${repo}";
        local dst="${user}/${repo}";

        while true; do
            read -p "'github.com/${dst}.git' not found.
    Fork '${src}' into '${dst}' now (y/n)? " CHOICE </dev/tty
            case $CHOICE in
                [Nn]* ) fork="${src}"; break;;
                [Yy]* ) fork="${dst}";
                        gh repo fork "${src}" --clone=false --default-branch-only;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
            unset CHOICE;
        done;
    fi

    if [[ ! -d ~/${dest}/.git ]]; then
        gh repo clone ${fork} ~/${dest} ${args:+-- $args};
    fi
}

clone_github_repo "$@";
