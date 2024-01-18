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
#  -h,--help,--usage     print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Filter the results to exclude <repo> entries.
#                        (default: none)
#  -r,--repo <repo>      Filter the results to only include <repo> entries.
#                        (default: all repositories)

. devcontainer-utils-parse-args-from-docstring;

python_conda_pkg_names() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

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

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"python-conda-pkg-names"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(python_conda_pkg_names "$@");
