#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

# Generate the devcontainer
. ./scripts/generate.sh "$@";

env='VAULT_HOST=https://vault.ops.k8s.rapids.ai';

# Start the devcontainer
devcontainer up \
    --skip-post-attach \
    --remote-env "$env" \
    --remove-existing-container \
    --workspace-folder "${workspace}" \
    --cache-from "docker.io/rapidsai/devcontainers:${tag}" \
    ;

container_id="$(docker ps | grep -P "vsc-${workspace#"${TMPDIR:-/tmp}/"}-[0-9a-z]{64}-uid" | cut -d' ' -f1)";

cmd="${@:3}";

trap "docker rm -f '${container_id}'" EXIT;

docker exec -it -u coder -w /home/coder -e "${env}" "${container_id}" ${cmd:-/bin/bash -li};
