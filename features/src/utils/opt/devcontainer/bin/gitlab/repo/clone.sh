#! /usr/bin/env bash

set -euo pipefail;

clone_gitlab_repo() {

    . /opt/devcontainer/bin/gitlab/cli/init.sh;
    if [[ -z "$GITLAB_USER" ]]; then exit 1; fi

    local user="$GITLAB_USER";
    local orig="${1:?orig is required}"; shift;
    local repo="${1:?repo is required}"; shift;
    local dest="${1:-$repo}";
    local args="${@:1}";

    local src="${orig}/${repo}";
    local dst="${user}/${repo}";

    local fork="$(glab repo view "${dst}" &>/dev/null; \
        if [ $? -eq 0 ]; then echo "${dst}"; fi;)";

    if [[ -z "$fork" ]]; then

        while true; do
            read -p "'gitlab.com/${dst}.git' not found.
Fork '${src}' into '${dst}' now (y/n)? " CHOICE </dev/tty
            case $CHOICE in
                [Nn]* ) fork="${src}"; break;;
                [Yy]* ) fork="${dst}";
                        gh repo fork "${src}" --clone=false;
                        break;;
                * ) echo "Please answer 'y' or 'n'";;
            esac
            unset CHOICE;
        done;
    fi

    if [ ! -d ~/${dest}/.git ]; then
        glab repo clone ${fork} ~/${dest} ${args:+-- $args};
    fi

    unset NAME;
    unset UPSTREAM;
    unset REPO;
    unset FORK;
    unset ORIGIN_URL;
    unset UPSTREAM_URL;
}

clone_gitlab_repo "$@";
