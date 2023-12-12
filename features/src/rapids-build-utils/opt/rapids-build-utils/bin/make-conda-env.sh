#! /usr/bin/env bash

make_conda_env() {

    set -euo pipefail;

    local env_name="${1}";
    local env_file_name="${env_name}.yml";

    # Remove the current conda env if called with `-f|--force`
    if echo "${@:2}" | grep -qE '(\-f|\-\-force)'; then
        rm -rf "$HOME/.conda/envs/${env_name}" \
               "$HOME/.conda/envs/${env_file_name}";
    fi

    local cuda_version="${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}";
    cuda_version="$(grep -o '^[0-9]*.[0-9]' <<< "${cuda_version}")";

    local python_version="${PYTHON_VERSION:-$(python3 --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    local new_env_path="$(realpath -m /tmp/${env_file_name})";
    local old_env_path="$(realpath -m ~/.conda/envs/${env_file_name})";

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
        > "${new_env_path}";

        rm ${conda_env_yamls[@]};
    fi

    if test -f "${new_env_path}"; then

        # If the conda env doesn't exist, make one
        if ! conda info -e | grep -qE "^${env_name} "; then
            echo -e "Creating '${env_name}' conda environment\n" 1>&2;
            echo -e "Environment (${env_file_name}):\n" 1>&2;
            cat "${new_env_path}";
            echo "";

            mamba env create -n "${env_name}" -f "${new_env_path}";
        # If the conda env does exist but it's different from the generated one,
        # print the diff between the envs and update it
        elif ! diff -BNqw "${old_env_path}" "${new_env_path}" >/dev/null 2>&1; then
            echo -e "Updating '${env_name}' conda environment\n" 1>&2;
            echo -e "Environment (${env_file_name}):\n" 1>&2;

            # Print the diff to the console for debugging
            [ ! -f "${old_env_path}" ]                         \
             && cat "${new_env_path}"                          \
             || diff -BNyw "${old_env_path}" "${new_env_path}" \
             || true                                           \
             && echo "";

            # Update the current conda env + prune libs that were removed
            # conda fallback for https://github.com/mamba-org/mamba/issues/3059
            if grep -q "pip:" ${new_env_path}; then
                conda env update -n "${env_name}" -f "${new_env_path}" --prune --solver=libmamba
            else
                mamba env update -n "${env_name}" -f "${new_env_path}" --prune
            fi
        fi

        cp -a "${new_env_path}" "${old_env_path}";
    fi
}

. /opt/conda/etc/profile.d/conda.sh;
. /opt/conda/etc/profile.d/mamba.sh;

(make_conda_env "${DEFAULT_CONDA_ENV:-rapids}" "$@");

. /etc/profile.d/*-mambaforge.sh;
