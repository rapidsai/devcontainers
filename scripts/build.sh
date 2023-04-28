#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

# Generate the devcontainer
. ./scripts/generate.sh "$@";

# Build the devcontainer
exec devcontainer build \
    --workspace-folder "${workspace}" \
    --image-name "docker.io/rapidsai/devcontainers:${tag}" \
    ;
