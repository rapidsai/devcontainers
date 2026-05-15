#!/usr/bin/env bash

# Usage:
#  rapids-convert-ucxx-branch <branch>
#
# Convert a RAPIDS branch name to the corresponding UCXX branch name.

convert_ucxx_branch() {
    local branch="${1:?fatal: missing required positional argument <branch>}"

    if [[ "${branch}" =~ ^release/[0-9]{2}\.[0-9]{2}$ ]]; then
        local rapids_version="${branch#release/}"
        branch="release/$(curl -sL "https://version.gpuci.io/rapids/${rapids_version}")"
    fi

    echo "${branch}"
}

convert_ucxx_branch "$@" <&0
