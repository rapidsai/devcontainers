#!/usr/bin/env bash

# Usage:
#  rapids-make-conda-dependencies [OPTION]...
#
# Generate a combined conda environment YAML file for all repos.
#
# Boolean options:
#  -h,--help             print this text
#
# Options that require values:
#  -k,--key <key>        Only include the key(s)
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Omit dependencies for repo(s).
#                        (default: none)
#  --repo <repo>         Only include dependencies for repo(s).
#                        (default: all repositories)

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


    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -m,--manifest
        -o,--omit
        --repo
    ' - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'make-conda-env make-conda-dependencies';

    test ${#key[@]} -eq 0 && key=(all);

    local cuda_version="${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}";
    cuda_version="$(grep -o '^[0-9]*.[0-9]' <<< "${cuda_version}")";

    local python_version="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    local conda_env_yamls=();

    eval "$(rapids-list-repos "${OPTS[@]}")";

    local i;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [ -f ~/"${!repo_path}/dependencies.yaml" ]; then

            local py_length="${repo}_python_length";

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_name="${repo}_python_${j}_name";

                echo "Generating ${!py_name}'s conda env yml" 1>&2;

                local repo_keys=("${key[@]}" "${key[@]/%/_${!py_name//"-"/"_"}}");
                local keyi;

                for ((keyi=0; keyi < ${#repo_keys[@]}; keyi+=1)); do
                    local file="/tmp/${!repo_name}.${!py_name}.${repo_keys[$keyi]}.env.yaml";
                    conda_env_yamls+=("${file}");
                    generate_env_yaml                                                         \
                        "${file}"                                                             \
                        --file_key "${repo_keys[$keyi]}"                                      \
                        --output conda                                                        \
                        --config ~/"${!repo_path}/dependencies.yaml"                          \
                        --matrix "arch=$(uname -m);cuda=${cuda_version};py=${python_version}" \
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
        conda-merge "${conda_env_yamls[@]}"                                                              \
          | grep -v '^name:'                                                                             \
          | grep -v -P '^[ ]*?\- (\.git\@[^(main|master)])(.*?)$'                                        \
          | grep -v -P "^[ ]*?\- ($(tr -d '[:blank:]' <<< "${conda_noinstall[@]/%/ |}"))(=.*|>.*|<.*)?$" \
          ;

        rm -f "${conda_env_yamls[@]}";
    fi
}

make_conda_dependencies "$@";
