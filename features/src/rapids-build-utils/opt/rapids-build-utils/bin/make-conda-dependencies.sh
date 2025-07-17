#!/usr/bin/env bash

# Usage:
#  rapids-make-conda-dependencies [OPTION]...
#
# Generate a combined conda environment YAML file for all repos.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
#  -e,--exclude <file>     Path(s) to requirement files of packages to exclude.
#                          Can also be a file descriptor like '<(echo libucx)'.
#  -i,--include <file>     Path(s) to requirement files of packages to include.
#                          Can also be a file descriptor like '<(echo libucx)'.
#  -k,--key <key>        Only include the key(s)
#  --matrix-entry <entry>  Matrix entries, in the form 'key=value' to be added to the '--matrix' arg
#                          of rapids-dependency-file-generator.
#                          (can be passed multiple times)
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-3;
#  --repo <repo>         Only include dependencies for repo(s).
#                        (default: all repositories)

# shellcheck disable=SC1091
. rapids-generate-docstring;

generate_env_yaml() {
    (
        (rapids-dependency-file-generator "${@:2}" 2>/dev/null || echo "name: none") \
      | (grep -v '^#' || [ "$?" == "1" ]) \
      | tee "${1}" 1>/dev/null;
    ) & true
}

make_conda_dependencies() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --skip '-m,--manifest -o,--omit --repo' "$@" <&0)";

    eval "$(rapids-list-repos "${OPTS[@]}")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'make-conda-env make-conda-dependencies';

    test ${#exclude[@]} -eq 0 && exclude=();
    test ${#include[@]} -eq 0 && include=();
    test ${#matrix_entry[@]} -eq 0 && matrix_entry=();

    local -a _exclude=();
    local exc; for exc in "${exclude[@]}"; do
        # append '-f' so each file's contents will be treated as a list of patterns for 'grep'
        _exclude+=(-f "${exc}");
    done

    local -a _include=();
    local inc; for inc in "${include[@]}"; do
        # append '-f' so each file's contents will be treated as a list of patterns for 'grep'
        _include+=(-f "${inc}");
    done

    local cuda_version="${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}";
    cuda_version="$(grep -o '^[0-9]*.[0-9]' <<< "${cuda_version}")";

    local python_version="${PYTHON_VERSION:-$("${ORIG_PYTHON:-python3}" --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    local -a _matrix_selectors=(
        arch="$(uname -m)"
        cuda="${cuda_version}"
        py="${python_version}"
    );

    # add extra arguments (if there are conflicts, e.g. 'py=3.10;py=3.11', it's fine... the last one will win)
    test ${#matrix_entry[@]} -gt 0 && _matrix_selectors+=("${matrix_entry[@]}");
    local -r matrix_selectors=$(IFS=";"; echo "${_matrix_selectors[*]}")

    local conda_env_yamls=();

    local i;
    local j;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";
        local name="${!repo_name:-}";
        local path="${!repo_path:-}";

        if test -n "${name:+x}" \
        && test -n "${path:+x}" \
        && test -f ~/"${path}/dependencies.yaml"; then

            echo "Generating ${name}'s repo conda env yml" 1>&2;

            local dependency_keys=("${key[@]}");

            local repo_dependency_keys_length="${repo}_dependency_keys_length";
            for ((j=0; j < ${!repo_dependency_keys_length:-0}; j+=1)); do
                local dependency_key="${repo}_dependency_keys_${j}";
                dependency_key="${!dependency_key:-}";
                if test -n "${dependency_key:+x}"; then
                    dependency_keys+=("${dependency_key}");
                fi
            done

            if test ${#dependency_keys[@]} -eq 0; then
                dependency_keys=(all);
            fi

            local keys=("${dependency_keys[@]}");
            local keyi;

            for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                local file="/tmp/${name}.${keys[$keyi]}.env.yaml";
                conda_env_yamls+=("${file}");
                generate_env_yaml                          \
                    "${file}"                              \
                    --file-key "${keys[$keyi]}"            \
                    --output conda                         \
                    --config ~/"${path}/dependencies.yaml" \
                    --matrix "${matrix_selectors}"         \
                    ;
            done

            local cpp_length="${repo}_cpp_length";

            for ((j=0; j < ${!cpp_length:-0}; j+=1)); do
                local cpp_name="${repo}_cpp_${j}_name";
                local cpp_name="lib${!cpp_name}";

                echo "Generating ${cpp_name}'s conda env yml" 1>&2;

                local keys=("${dependency_keys[@]/%/_${cpp_name//"-"/"_"}}");
                local keyi;

                for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                    local file="/tmp/${name}.${cpp_name}.${keys[$keyi]}.env.yaml";
                    conda_env_yamls+=("${file}");
                    generate_env_yaml                          \
                        "${file}"                              \
                        --file-key "${keys[$keyi]}"            \
                        --output conda                         \
                        --config ~/"${path}/dependencies.yaml" \
                        --matrix "${matrix_selectors}"         \
                        ;
                done
            done

            local py_length="${repo}_python_length";

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_name="${repo}_python_${j}_name";
                local py_name="${!py_name}";

                echo "Generating ${py_name}'s conda env yml" 1>&2;

                local keys=("${dependency_keys[@]/%/_${py_name//"-"/"_"}}");
                local keyi;

                for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                    local file="/tmp/${name}.${py_name}.${keys[$keyi]}.env.yaml";
                    conda_env_yamls+=("${file}");
                    generate_env_yaml                          \
                        "${file}"                              \
                        --file-key "${keys[$keyi]}"            \
                        --output conda                         \
                        --config ~/"${path}/dependencies.yaml" \
                        --matrix "${matrix_selectors}"         \
                        ;
                done
            done
        fi
    done

    if test ${#conda_env_yamls[@]} -gt 0; then

        for ((i=0; i < ${#conda_env_yamls[@]}; i+=1)); do
            while ! test -f "${conda_env_yamls[$i]}"; do
                sleep 0.1;
            done
        done

        # shellcheck disable=SC2207
        local conda_noinstall=($(rapids-python-pkg-names) $(rapids-python-conda-pkg-names));

        # Generate a combined conda env yaml file.
        conda-merge "${conda_env_yamls[@]}"                                                                                   \
          | (grep -v '^name:'                                                                             || [ "$?" == "1" ]) \
          | (grep -v -P '^[ ]*?\- (\.git\@[^(main|master)])(.*?)$'                                        || [ "$?" == "1" ]) \
          | (grep -v -P "^[ ]*?\- ($(tr -d '[:blank:]' <<< "${conda_noinstall[@]/%/ |}"))(=.*|>.*|<.*)?$" || [ "$?" == "1" ]) \
          | ( if test ${#_exclude[@]} -gt 0; then grep -E -v "${_exclude[@]}" || [ "$?" == "1" ]; else cat -; fi            ) \
          | ( if test ${#_include[@]} -gt 0; then grep -E    "${_include[@]}" || [ "$?" == "1" ]; else cat -; fi            ) \
          ;

        rm -f "${conda_env_yamls[@]}";
    fi
}

make_conda_dependencies "$@" <&0;
