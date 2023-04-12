#! /usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

build_image() {

    local cwd="$(pwd)";
    local img="${1:-"./images/cpp"}";
    img="$(realpath -m "$img")";
    img="${img#"$cwd/images/"}";

    exec devcontainer build \
        --workspace-folder $cwd/images/$img \
        --image-name docker.io/rapidsai/devcontainers:23.06-$img-ubuntu22.04;
}

build_image "$@";
