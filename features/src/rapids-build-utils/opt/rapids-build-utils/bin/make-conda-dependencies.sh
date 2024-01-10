#! /usr/bin/env bash

make_conda_dependencies() {

    set -euo pipefail;

    local keys=();

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            k|keys                            |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    if test -v k; then keys=(${k[@]}); fi
    if test ${#keys[@]} -eq 0; then
        keys=(all);
    fi

    local cuda_version="${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}";
    cuda_version="$(grep -o '^[0-9]*.[0-9]' <<< "${cuda_version}")";

    local python_version="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    local conda_noinstall=();
    local conda_env_yamls=();

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    local i;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";

        if [ -f ~/"${!repo_path}/dependencies.yaml" ]; then
            conda_noinstall+=("$(rapids-python-conda-pkg-names --repo "${!repo_name}")");

            echo "Generating ${!repo_name}'s conda env yml" 1>&2;

            local repo_keys=(${keys[@]} ${keys[@]/%/_${!repo_name}});
            local keyi;

            for ((keyi=0; keyi < ${#repo_keys[@]}; keyi+=1)); do
                if rapids-dependency-file-generator                                       \
                    --file_key ${repo_keys[$keyi]}                                        \
                    --output conda                                                        \
                    --config ~/"${!repo_path}/dependencies.yaml"                          \
                    --matrix "arch=$(uname -m);cuda=${cuda_version};py=${python_version}" \
                >> /tmp/${!repo_name}${keyi}.yaml 2>/dev/null; then
                    conda_env_yamls+=("/tmp/${!repo_name}${keyi}.yaml");
                fi
            done
        fi
    done

    if test ${#conda_env_yamls[@]} -gt 0; then

        # Generate a combined conda env yaml file.
        conda-merge ${conda_env_yamls[@]}                             \
          | grep -v '^name:'                                          \
          | grep -v -P '^(.*?)\-(.*?)rapids-(.*?)$'                   \
          | grep -v -P '^(.*?)\-(.*?)(\.git\@[^(main|master)])(.*?)$' \
          | grep -v -P "^(.*?)\-(.*?)($(rapids-join-strings "|" ${conda_noinstall[@]}))(=.*|>.*|<.*)?$" \
          ;

        rm ${conda_env_yamls[@]};
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(make_conda_dependencies "$@");
