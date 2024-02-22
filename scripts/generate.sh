#! /usr/bin/env bash

generate_devcontainer() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    # shellcheck disable=SC2155
    local workspace="$(mktemp -d)";

    # rm -rf "${workspace}";
    cp -ar image/.devcontainer "${workspace}/";
    # rm "${workspace}/.devcontainer/features";
    ln -sfn "$(realpath ./features)" "${workspace}/.devcontainer/features";

    # Generate tag and devcontainer.json
    .github/actions/devcontainer-json/action.sh           \
        "${1:-"ubuntu:22.04"}" "${2:-"[]"}" "${3:-"{}"}"  \
        3>&1                                              \
        4> "${workspace}/.devcontainer/devcontainer.json" \
        ;

    # Report the workspace path
    echo "workspace=${workspace}";
}

generate_devcontainer "$@";
