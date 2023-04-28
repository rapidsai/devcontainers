#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..";

workspace="${TMPDIR:-/tmp}/rapidsai-devcontainers-tmp";

rm -rf "${workspace}";
cp -ar image "${workspace}";
rm "${workspace}/.devcontainer/features";
ln -s "$(realpath ./features/src)" "${workspace}/.devcontainer/features";

# Generate tag and devcontainer.json
.github/actions/devcontainer-json/action.sh \
    "${1:-"ubuntu:22.04"}" "${2:-"[]"}"     \
    3> "${workspace}/tag.txt"               \
    4> "${workspace}/.devcontainer/devcontainer.json" \
    ;

# Read the tag into the environment
eval "$(cat "${workspace}/tag.txt")";

# Print the generated devcontainer JSON
cat "${workspace}/.devcontainer/devcontainer.json";
