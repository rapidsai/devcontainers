export MAMBA_NO_BANNER="${MAMBA_NO_BANNER:-1}";

for default_conda_env_name in ${DEFAULT_CONDA_ENV:-} ${CONDA_DEFAULT_ENV:-} base; do
    if [ -z "${default_conda_env_name:-}" ]; then continue; fi
    if echo "${CONDA_PROMPT_MODIFIER:-}" | grep -qF "($default_conda_env_name)"; then
        break;
    fi
    conda activate "$default_conda_env_name" 2>/dev/null && break || continue;
done;

if [ -n "${CONDA_EXE:-}" ]; then
    for conda_bin_path in "$(dirname "$(dirname "${CONDA_EXE}")")/condabin" "/opt/conda/bin"; do
        if [ -n "${PATH##*"$conda_bin_path"*}" ]; then
            export PATH="$conda_bin_path:$PATH";
        fi
    done
fi
