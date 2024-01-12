#! /usr/bin/env bash

make_pip_dependencies() {

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
        keys=(py_build py_run py_test all);
    fi

    local cuda_version="${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}";
    cuda_version="$(grep -o '^[0-9]*.[0-9]*.[0-9]' <<< "${cuda_version}")";
    local cuda_version_major="$(cut -d'.' -f1 <<< "${cuda_version}")";
    local cuda_version_minor="$(cut -d'.' -f2 <<< "${cuda_version}")";
    local cuda_version_patch="$(cut -d'.' -f3 <<< "${cuda_version}")";
    local cuda_version_mm="${cuda_version_major}.${cuda_version_minor:-0}";
    cuda_version="${cuda_version_mm}.${cuda_version_patch:-0}";

    local python_version="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    local pip_reqs_txts=();

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

                echo "Generating ${!py_name}'s requirements.txt" 1>&2;

                local repo_keys=(${keys[@]} ${keys[@]/%/_${!py_name//"-"/"_"}});
                local keyi;

                for ((keyi=0; keyi < ${#repo_keys[@]}; keyi+=1)); do
                    if rapids-dependency-file-generator                                          \
                        --file_key ${repo_keys[$keyi]}                                           \
                        --output requirements                                                    \
                        --config ~/"${!repo_path}/dependencies.yaml"                             \
                        --matrix "arch=$(uname -m);cuda=${cuda_version_mm};py=${python_version}" \
                        `# --stdout` \
                    >> /tmp/${!repo_name}.${!py_name}.${keyi}.requirements.txt 2>/dev/null; then
                        pip_reqs_txts+=("/tmp/${!repo_name}.${!py_name}.${keyi}.requirements.txt");
                    fi
                done
            done
        fi
    done

    if test ${#pip_reqs_txts[@]} -gt 0; then

        local pip_noinstall=();

        # add all python packages to the noinstall list.
        for pkg in $(rapids-python-pkg-names); do
            pip_noinstall+=("${pkg}" "${pkg}-cu.*");
            if test -z "${pkg##*"-"*}"; then
                pip_noinstall+=("${pkg//"-"/"_"}" "${pkg//"-"/"_"}-cu.*")
            fi
            if test -z "${pkg##*"_"*}"; then
                pip_noinstall+=("${pkg//"_"/"-"}" "${pkg//"_"/"-"}-cu.*")
            fi
        done

        # Generate a combined requirements.txt file
        cat ${pip_reqs_txts[@]}                                                                    \
          | grep -v '^#'                                                                           \
          | grep -v -P "^($(tr -d '[:blank:]' <<< "${pip_noinstall[@]/%/|}"))(=.*|>.*|<.*)?$"      \
          | sed -E "s/-cu([0-9]+)/-cu${cuda_version_major}/g"                                      \
          | sed -E "s/cupy-cuda[0-9]+x/cupy-cuda${cuda_version_major}x/g"                          \
          | sed -E "s/cuda-python.*/cuda-python>=${cuda_version},<$((cuda_version_major+1)).0a0/g" \
        ;

        rm ${pip_reqs_txts[@]};
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

make_pip_dependencies "$@";
