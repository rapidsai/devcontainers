#! /usr/bin/env bash

run_devcontainer() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    # Generate the devcontainer
    eval "$(./scripts/generate.sh "$@" | xargs -r -d'\n' -I% echo -n local %\;)";

    # Build and tag the devcontainer
    devcontainer build \
        --workspace-folder "${workspace}" \
        --image-name "docker.io/rapidsai/devcontainers:${tag}" \
        ;

    mkdir -p -m 0755 .scratch/.{aws,cache,config};

    local env=();
    env+=("TERM=${TERM}");
    env+=("LINES=$(tput lines)");
    env+=("COLUMNS=$(tput cols)");
    env+=("SCCACHE_REGION=us-east-2");
    env+=("SCCACHE_BUCKET=rapids-sccache-devs");
    env+=("VAULT_HOST=https://vault.ops.k8s.rapids.ai");
    env+=("HISTFILE=/home/coder/.cache/._bash_history");

    # Start the devcontainer
    devcontainer up \
        --skip-post-attach \
        $(echo "${env[@]}" | xargs -r -d' ' -I% echo -n '--remote-env % ')\
        --remove-existing-container \
        --terminal-rows "$(tput lines)" \
        --terminal-columns "$(tput cols)" \
        --workspace-folder "${workspace}" \
        --mount-workspace-git-root false \
        --cache-from "docker.io/rapidsai/devcontainers:${tag}" \
        --mount "type=bind,source=$(pwd)/.scratch/.aws,target=/home/coder/.aws" \
        --mount "type=bind,source=$(pwd)/.scratch/.cache,target=/home/coder/.cache" \
        --mount "type=bind,source=$(pwd)/.scratch/.config,target=/home/coder/.config" \
        --mount "type=bind,source=$(pwd)/features/src/utils/opt/devcontainer,target=/opt/devcontainer" \
        --additional-features '{ "./features/rapids-build-utils": {} }' \
        --mount "type=bind,source=$(pwd)/features/src/rapids-build-utils/opt/rapids-build-utils,target=/opt/rapids-build-utils" \
        ;

    local container_id="$(docker ps | grep -P "vsc-${workspace#"${TMPDIR:-/tmp}/"}-[0-9a-z]{64}-uid" | cut -d' ' -f1)";

    local cmd="${@:3}";

    trap "docker rm -f '${container_id}'" EXIT;

    docker exec -it -u coder -w /home/coder \
        $(echo "${env[@]}" | xargs -r -d' ' -I% echo -n '-e % ')\
        "${container_id}" ${cmd:-/bin/bash};
}

run_devcontainer "$@";
