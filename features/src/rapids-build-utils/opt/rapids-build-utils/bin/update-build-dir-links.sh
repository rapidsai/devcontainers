#!/usr/bin/env bash

# Usage:
#  rapids-update-build-dir-links [OPTION]...
#
# Update the `build/latest` symlink for each library.
#
# Boolean options:
#  -h,--help             Print this text.
#  -v,--verbose          Verbose output.
#
# Options that require values:
#  -j,--parallel <num>   Update <num> libraries in parallel
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_get_library_paths() {
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
                echo "${cpp_path}";
            done

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_sub_dir="${repo}_python_${j}_sub_dir";
                local py_path=~/"${!repo_path:-}${!py_sub_dir:+/${!py_sub_dir}}";
                if rapids-python-uses-scikit-build-core "${py_path}"; then
                    echo "${py_path}";
                fi
            done
        fi
    done
}

_update_build_dir_links() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-v,--verbose' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 0 "$@")";

    eval "$(rapids-list-repos "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'update-build-dir-links';

    _get_library_paths | tr '\n' '\0' \
  | xargs ${v:+-t} -r -0 -n1 -P${n_jobs} bash -c \
  " if ! rapids-get-cmake-build-dir --skip-build-type -- \"\$0\" >/dev/null; then exit 255; fi";
}

_update_build_dir_links "$@" <&0;
