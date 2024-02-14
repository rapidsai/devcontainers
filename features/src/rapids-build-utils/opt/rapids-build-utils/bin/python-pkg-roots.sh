#!/usr/bin/env bash

# Usage:
#  rapids-python-pkg-roots [OPTION]...
#
# List python package source dirs as determined by manifest.yaml
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

python_pkg_roots() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'python-pkg-roots';

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

python_pkg_roots "$@" <&0;
