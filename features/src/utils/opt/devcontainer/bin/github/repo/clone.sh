#! /usr/bin/env bash

set -euo pipefail;

. /opt/devcontainer/bin/github/cli/init.sh;
if [[ -z "$GITHUB_USER" ]]; then exit 1; fi

NAME="$2";
UPSTREAM="$1/$NAME";
REPO="$GITHUB_USER/$NAME";
FORK="$(gh repo list $GITHUB_USER --fork --json name --jq ". | map(select(.name == \"$NAME\")) | map(.name)[]")";

if [[ ! "$FORK" ]]; then
    ORIGIN_URL="github.com/$REPO";
    UPSTREAM_URL="github.com/$UPSTREAM";

    while true; do

        read -p "\`$UPSTREAM_URL\` not found.
Fork \`$UPSTREAM_URL\` into \`$ORIGIN_URL\` now (y/n)? " CHOICE </dev/tty

        case $CHOICE in
            [Nn]* ) REPO="$UPSTREAM"; break;;
            [Yy]* ) gh repo fork "$UPSTREAM" --clone=false; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
        unset CHOICE;
    done;
fi

if [[ ! -d ~/${3:-$NAME}/.git ]]; then
    gh repo clone "$REPO" ~/${3:-$NAME};
fi

unset NAME;
unset UPSTREAM;
unset REPO;
unset FORK;
unset ORIGIN_URL;
unset UPSTREAM_URL;
