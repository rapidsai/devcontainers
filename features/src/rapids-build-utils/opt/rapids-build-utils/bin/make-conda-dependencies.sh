#! /usr/bin/env bash

make_conda_dependencies() {

    set -euo pipefail;

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
            conda_env_yamls+=("/tmp/${!repo_name}.yaml");
            conda_noinstall+=("$(rapids-python-conda-pkg-names --repo "${!repo_name}")");
            echo "Generating ${!repo_name}'s conda env yml" 1>&2;
            /opt/conda/bin/rapids-dependency-file-generator \
                --file_key all \
                --output conda \
                --config ~/"${!repo_path}/dependencies.yaml" \
                --matrix "arch=$(uname -m);cuda=${cuda_version};py=${python_version}" \
            > /tmp/${!repo_name}.yaml;
        fi
    done

    if test ${#conda_env_yamls[@]} -gt 0; then

        # Generate a combined conda env yaml file.
        /opt/conda/bin/conda-merge ${conda_env_yamls[@]} \
          | grep -v '^name:' \
          | grep -v -P '^(.*?)\-(.*?)rapids-(.*?)$' \
          | grep -v -P '^(.*?)\-(.*?)(\.git\@[^(main|master)])(.*?)$' \
          | grep -v -P "^(.*?)\-(.*?)($(rapids-join-strings "|" ${conda_noinstall[@]}))(=.*|>.*|<.*)?$" \
          ;

        rm ${conda_env_yamls[@]};
    fi
}

(make_conda_dependencies "$@");
