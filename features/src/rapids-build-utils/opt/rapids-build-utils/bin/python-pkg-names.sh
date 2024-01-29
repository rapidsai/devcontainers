#!/usr/bin/env bash

# Usage:
#  rapids-python-pkg-names [OPTION]...
#
# List python package names as determined by manifest.yaml
#
# Boolean options:
#  -h,--help,--usage     print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to only include <repo> entries.
#                        (default: all repositories)

python_pkg_names() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    eval "$(rapids-list-repos "$@")";

    local i;
    local j;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_path="${repo}_path";
        local py_length="${repo}_python_length";

        if test -d ~/"${!repo_path:-}/.git"; then
            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_name="${repo}_python_${j}_name";
                echo "${!py_name}";
            done
        fi
    done
}

python_pkg_names "$@";
