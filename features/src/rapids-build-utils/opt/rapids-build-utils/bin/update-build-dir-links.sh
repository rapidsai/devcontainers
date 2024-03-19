#!/usr/bin/env bash

# Usage:
#  rapids-update-build-dir-links [OPTION]...
#
# List python package names as determined by manifest.yaml
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

update_build_dir_links() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'update-build-dir-links';

    local i;
    local j;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_path="${repo}_path";
        local cpp_length="${repo}_cpp_length";
        local py_length="${repo}_python_length";

        if test -d ~/"${!repo_path:-}/.git"; then

            for ((j=0; j < ${!cpp_length:-0}; j+=1)); do
                local cpp_sub_dir="${repo}_cpp_${j}_sub_dir";
                local cpp_path=~/"${!repo_path:-}${!cpp_sub_dir:+/${!cpp_sub_dir}}";
                rapids-get-cmake-build-dir --skip-build-type -- "${cpp_path}" >/dev/null;
            done

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_sub_dir="${repo}_python_${j}_sub_dir";
                local py_path=~/"${!repo_path:-}${!py_sub_dir:+/${!py_sub_dir}}";
                # TODO: Should this also preserve the _skbuild directory for scikit-build projects?
                if rapids-python-uses-scikit-build-core "${py_path}"; then
                    rapids-get-cmake-build-dir --skip-build-type -- "${py_path}" >/dev/null;
                fi
            done
        fi
    done
}

update_build_dir_links "$@" <&0;
