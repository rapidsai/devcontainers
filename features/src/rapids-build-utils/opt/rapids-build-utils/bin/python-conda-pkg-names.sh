#!/usr/bin/env bash

# Usage:
#  rapids-python-conda-pkg-names [OPTION]...
#
# Read the `name="<pkg>"` fields from the meta.yaml files in each repository,
# as determined by manifest.yaml. This seems to be the most reliable way to
# determine the actual list of package names to exclude from the combined
# conda env.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

python_conda_pkg_names() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'python-conda-pkg-names';

    local i;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_path="${repo}_path";

        if test -d ~/"${!repo_path:-}/.git"; then
            # the regex will continue until morale improves
            find ~/"${!repo_path}/"            \
              -type f -name 'meta.yaml'        \
              ! -path '*/.conda/*'             \
              ! -path '*/build/*'              \
              ! -path '*/_skbuild/*'           \
              ! -path '*/target/cmake-build/*' \
                -exec grep -E 'name: ?' {} \;  \
              2>/dev/null                      \
              | tr -d '[:blank:]'              \
              | cut -d':' -f2                  \
            ;
        fi
    done
}

python_conda_pkg_names "$@" <&0;
