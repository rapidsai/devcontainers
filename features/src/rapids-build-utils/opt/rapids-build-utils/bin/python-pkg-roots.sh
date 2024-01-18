#!/usr/bin/env bash

# Usage:
#  rapids-python-pkg-roots [OPTION]...
#
# List python package source dirs as determined by manifest.yaml
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

python_pkg_roots() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

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
                local py_sub_dir="${repo}_python_${j}_sub_dir";
                echo "${!repo_path:-}${!py_sub_dir:+/${!py_sub_dir}}";
            done
        fi
    done
}

(python_pkg_roots "$@");
