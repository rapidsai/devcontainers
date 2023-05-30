#! /usr/bin/env bash

build_devcontainer() {

    set -euo pipefail;

    # PS4='+ ${LINENO}: '; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    # Generate the devcontainer
    eval "$(./scripts/generate.sh "$@" | xargs -r -d'\n' -I% echo -n local %\;)";

    # Build the devcontainer
    exec devcontainer build \
        --workspace-folder "${workspace}" \
        --image-name "docker.io/rapidsai/devcontainers:${tag}" \
        ;
}

build_devcontainer "$@";
