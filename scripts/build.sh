#! /usr/bin/env bash

build_devcontainer() {

    set -euo pipefail;

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    # cd to the repo root
    cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

    # Generate the devcontainer
    eval "$(./scripts/generate.sh "$@" | xargs -r -d'\n' -I% echo -n local %\;)";

    echo "tag=${tag-}" >&2;
    echo "workspace=${workspace-}" >&2;

    if ! test -n "${workspace-}" || ! test -n "${tag-}"; then exit 1; fi;

    # Print the generated devcontainer JSON
    cat "${workspace}/.devcontainer/devcontainer.json" >&2;

    cleanup() {
        code=$?;
        set -x;
        find ./features/src -maxdepth 1 -type d -name '*\.[0-9]' -exec rm -r "{}" \;
        rm -rf "${1}";
        exit "${code}";
    }

    # shellcheck disable=SC2064
    trap "cleanup '${workspace}'" EXIT;

    # Build the devcontainer
    devcontainer build \
        --workspace-folder "${workspace}" \
        --cache-from "docker.io/rapidsai/devcontainers:${tag}" \
        --image-name "docker.io/rapidsai/devcontainers:${tag}" \
        --output "type=docker,compression=zstd,force-compression=true,oci-mediatypes=true" \
        "${@:3}";
}

build_devcontainer "$@";
