#! /usr/bin/env bash

set -euo pipefail;

. /opt/devcontainer/bin/gitlab/cli/init.sh;
if [[ -z "$GITLAB_USER" ]]; then exit 1; fi

NAME="$2";
UPSTREAM="$1/$NAME";
REPO="$GITLAB_USER/$NAME";
FORK="$(glab repo view "$REPO" &>/dev/null; if [ $? -eq 0 ]; then echo "$REPO"; fi;)";

if [[ -z "$FORK" ]]; then
    ORIGIN_URL="gitlab.com/$REPO";
    UPSTREAM_URL="gitlab.com/$UPSTREAM";

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

if [ ! -d ~/${3:-$NAME}/.git ]; then
    glab repo clone "$REPO" ~/${3:-$NAME};
fi

unset NAME;
unset UPSTREAM;
unset REPO;
unset FORK;
unset ORIGIN_URL;
unset UPSTREAM_URL;
