#! /usr/bin/env bash

build_devcontainer() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    # Generate the devcontainer
    eval "$(./scripts/generate.sh "$@" | xargs -r -d'\n' -I% echo -n local %\;)";

    trap "$(cat <<________
        code=\$?;
        find ./features/src -maxdepth 1 -type d -name '*\.[0-9]' -exec rm -r "{}" \;
        exit \$code;
________
)" EXIT;

    # Build the devcontainer
    devcontainer build \
        --workspace-folder "${workspace}" \
        --cache-from "docker.io/rapidsai/devcontainers:${tag}" \
        --image-name "docker.io/rapidsai/devcontainers:${tag}" \
        ;
}

build_devcontainer "$@";
