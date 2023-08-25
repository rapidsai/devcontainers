#! /usr/bin/env bash

# List python package names as determined by manifest.yaml
python_pkg_names() {
    set -euo pipefail;

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

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

(python_pkg_names "$@");
