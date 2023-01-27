#! /usr/bin/env bash

if [[ "${CODESPACES:-false}" == true && -f ~/.devcontainer/.postAttachCommandMarker ]]; then
    exit 0;
fi

/opt/devcontainer/bin/git/init.sh;

if ! /opt/devcontainer/bin/vault/s3/test.sh 2>&1 >/dev/null; then
    /opt/devcontainer/bin/vault/s3/init.sh;
fi

for cmd in $(find /opt -type f -name post-attach-command.sh ! -wholename $(realpath -m $0)); do
    . $cmd;
done

if [[ "${CODESPACES:-false}" == true ]]; then
    touch ~/.devcontainer/.postAttachCommandMarker;
fi
