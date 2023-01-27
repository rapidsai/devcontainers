. /opt/conda/etc/profile.d/conda.sh;
. /opt/conda/etc/profile.d/mamba.sh;

for default_conda_env_name in ${DEFAULT_CONDA_ENV:-} ${CONDA_DEFAULT_ENV:-} base; do
    if [[ -z "${default_conda_env_name:-}" ]]; then continue; fi
    if [[ "${CONDA_PROMPT_MODIFIER:-}" == *"($default_conda_env_name)"*  ]]; then
        break;
    fi
    conda activate "$default_conda_env_name" 2>/dev/null && break || continue;
done;
