#! /usr/bin/env bash

generate_devcontainer() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    local workspace="${TMPDIR:-/tmp}/rapidsai-devcontainers-tmp";

    rm -rf "${workspace}";
    cp -ar image "${workspace}";
    rm "${workspace}/.devcontainer/features";
    ln -s "$(realpath ./features/src)" "${workspace}/.devcontainer/features";

    # Generate tag and devcontainer.json
    .github/actions/devcontainer-json/action.sh \
        "${1:-"ubuntu:22.04"}" "${2:-"[]"}"     \
        3>&1                                    \
        4> "${workspace}/.devcontainer/devcontainer.json" \
        ;

    # Report the workspace path
    echo "workspace=${workspace}";

    # Print the generated devcontainer JSON
    cat "${workspace}/.devcontainer/devcontainer.json" >&2;
}

generate_devcontainer "$@";
