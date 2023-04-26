#! /usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

rm_image() {

    local cwd="$(pwd)";
    local img="${1:-"./images/cpp"}";
    img="$(realpath -m "$img")";
    img="${img#"$cwd/images/"}";

    exec docker rm -f "$(docker ps | grep -P "vsc-$img-[0-9a-z]{64}-uid" | cut -d' ' -f1)";
}

rm_image "$@";
