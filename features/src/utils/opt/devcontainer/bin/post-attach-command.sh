#! /usr/bin/env bash

if [[ "${CODESPACES:-false}" == true && -f ~/.devcontainer/.postAttachCommandMarker ]]; then
    exit 0;
fi

/opt/devcontainer/bin/git/init.sh;

# Refresh the S3 creds if they've expired
if ! /opt/devcontainer/bin/vault/s3/test.sh 2>&1 >/dev/null; then
    /opt/devcontainer/bin/vault/s3/init.sh;
fi

. /opt/devcontainer/bin/vault/s3/export.sh;

for cmd in $(find /opt -type f -name post-attach-command.sh ! -wholename $(realpath -m "${BASH_SOURCE[0]}")); do
    . $cmd;
done

if [[ "${CODESPACES:-false}" == true ]]; then
    mkdir -p ~/.devcontainer && touch ~/.devcontainer/.postAttachCommandMarker;
fi
