#!/usr/bin/env bash
#
# Launch devcontainers in a command line interface.
#
# This script can be run from inside of a git repo that defines devcontainers.
# The user is prompted to select one of the devcontainers, then the
# devcontainer is launched. The user can also provide a devcontainer name like
# "cuda12.0-conda" as an argument to this script. If invoked multiple times
# with the same devcontainer configuration, the CLI instances will reuse the
# same running container. After the last shell utilizing that devcontainer is
# closed, the container is torn down.
#
# This script requires the devcontainer CLI.

set -euo pipefail

create_menu() {
  select option; do
    if [ 1 -le "$REPLY" ] && [ "$REPLY" -le "$#" ]; then
      echo "${option}"
      break;
    else
      echo "Invalid choice: Select a number 1-$#" >&2
    fi
  done
}

choose_container() {
    echo "Select a container (or provide it as a positional argument):" >&2
    containers=()
    while IFS= read -r -d '' dir; do
        containers+=("$(basename $dir)")
    done < <(find ${devcontainers_root}/.devcontainer -mindepth 1 -maxdepth 1 -type d -print0 | sort -z --version-sort)
    create_menu "${containers[@]}"
}

find_container() {
    docker ps --quiet \
      --filter label=devcontainer.local_folder=${devcontainers_root} \
      --filter label=devcontainer.config_file=${devcontainer_config}
}

container_up() {
    devcontainer up --config ${devcontainer_config} --workspace-folder ${devcontainers_root}
}

container_exec() {
    devcontainer exec --config ${devcontainer_config} --workspace-folder ${devcontainers_root} bash
}

container_teardown() {
    # If this is the last active shell, stop and remove the container
    container_id="$(find_container)"
    num_active_shells=$(docker exec "${container_id}" ps aux | grep -c "/bin/sh")
    if [[ ${num_active_shells} -le 1 ]]; then
        echo "All devcontainers are closed. Stopping and removing container ${container_id}."
        docker stop "${container_id}"
        docker rm "${container_id}"
    fi
}

main() {
    if ! command -v devcontainer &> /dev/null; then
        echo "devcontainer CLI must be installed."
        echo "Try running 'npm install -g @devcontainers/cli'."
        exit 1
    fi

    devcontainers_root=$(git rev-parse --show-toplevel 2>/dev/null || realpath devcontainers)
    if [ -d ${devcontainers_root} ]; then
        echo "Using devcontainers in ${devcontainers_root}."
    else
        echo "Devcontainers could not be found."
        exit 1
    fi
    container_name=${1:-$(choose_container)}
    devcontainer_config="${devcontainers_root}/.devcontainer/${container_name}/devcontainer.json"

    if [ -z "$(find_container)" ]; then
        container_up
    fi
    container_exec
    container_teardown
}

main