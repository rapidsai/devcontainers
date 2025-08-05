#! /usr/bin/env bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

find ./features/src -mindepth 1 -maxdepth 1 -type d -exec \
    bash -c 'rm -rf {}/common && cp -ar ./features/common {}/' \;

cp ./features/common/find-version-from-git-tags.sh ./features/src/utils/opt/devcontainer/bin/sccache/find-version-from-git-tags.sh
