#! /usr/bin/env bash

# Read the `name="<pkg>"` fields from the meta.yaml files in each repository,
# as determined by manifest.yaml. This seems to be the most reliable way to
# determine the actual list of package names to exclude from the combined
# conda env.
python_conda_pkg_names() {
    set -euo pipefail;

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    local i;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_path="${repo}_path";

        if test -d ~/"${!repo_path:-}/.git"; then
            # the regex will continue until morale improves
            find ~/"${!repo_path}/"           \
              -type f -name 'meta.yaml'       \
              ! -path '*/.conda/*'            \
              ! -path '*/build/*'             \
              ! -path '*/_skbuild/*'          \
                -exec grep -E 'name: ?' {} \; \
              2>/dev/null                     \
              | tr -d '[:blank:]'             \
              | cut -d':' -f2                 \
            ;
        fi
    done
}

(python_conda_pkg_names "$@");
