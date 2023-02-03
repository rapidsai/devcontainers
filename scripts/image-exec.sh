#! /usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

exec_image() {

    local cwd="$(pwd)";
    local img="${1:-"./images/cpp"}";
    img="$(realpath -m "$img")";
    img="${img#"$cwd/images/"}";
    local cmd="${@:2}";

    exec docker exec -it -u coder -w /home/coder \
        -e 'VAULT_HOST=https://vault.ops.k8s.rapids.ai' \
        $(docker ps | grep -P "vsc-$img-[0-9a-z]{32}-uid" | cut -d' ' -f1) \
        ${cmd:-bash -li};
}

exec_image "$@";
