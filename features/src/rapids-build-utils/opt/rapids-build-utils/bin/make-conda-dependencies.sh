#! /usr/bin/env bash

generate_env_yaml() {
    (
        (rapids-dependency-file-generator ${@:2} 2>/dev/null || echo "name: none") \
      | (grep -v '^#' || [ "$?" == "1" ]) \
      | tee "${1}" 1>/dev/null;
    ) & true
}

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

    local conda_env_yamls=();

    eval "$(                                  \
        rapids-list-repos ${__rest__[@]}      \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

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

                local repo_keys=(${keys[@]} ${keys[@]/%/_${!py_name//"-"/"_"}});
                local keyi;

                for ((keyi=0; keyi < ${#repo_keys[@]}; keyi+=1)); do
                    local file="/tmp/${!repo_name}.${!py_name}.${repo_keys[$keyi]}.env.yaml";
                    conda_env_yamls+=("${file}");
                    generate_env_yaml                                                         \
                        "${file}"                                                             \
                        --file_key ${repo_keys[$keyi]}                                        \
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

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(make_conda_dependencies "$@");