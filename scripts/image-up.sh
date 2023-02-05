#! /usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

image_up() {

    local cwd="$(pwd)";
    local img="${1:-"./images/cpp"}";
    img="$(realpath -m "$img")";
    img="${img#"$cwd/images/"}";

    export BUILDKIT_INLINE_CACHE=0
    exec devcontainer up \
        --remove-existing-container \
        --remote-env 'VAULT_HOST=https://vault.ops.k8s.rapids.ai' \
        --workspace-folder $cwd/images/$img \
        --cache-from docker.io/rapidsai/devcontainers:23.04-$img-ubuntu22.04;
}

image_up "$@";
