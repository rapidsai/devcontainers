#!/usr/bin/env bash

# Usage:
#  rapids-merge-compile-commands-json [OPTION]...
#
# Merges each build's compile_commands.json into one giant compile_commands.json
#
# Boolean options:
#  -h,--help                  Print this text.
#
# Options that require values:
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-1;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_list_repo_paths() {
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

merge_compile_commands_json() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'merge-compile-commands-json';

    eval "$(_parse_args "$@" <&0)";
    eval "$(rapids-list-repos "$@")";

    readarray -t dirs < <(                                             \
        _list_repo_paths                                               \
      | xargs -r -I% -P$(nproc)                                        \
        rapids-get-cmake-build-dir --skip-links --skip-build-type -- % \
      | xargs -r -I% echo %/                                           \
    );

    if test ${#dirs[@]} -gt 0; then
        readarray -t files < <(find "${dirs[@]}" -maxdepth 1 -type f -name compile_commands.json);
        if test ${#files[@]} -gt 0; then
            jq -s '. | flatten' "${files[@]}";
        fi
    fi
}


merge_compile_commands_json "$@" <&0;
