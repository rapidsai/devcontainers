export MAMBA_NO_BANNER="${MAMBA_NO_BANNER:-1}";

# Temporarily allow unbound variables for conda activation.
nounseton="$(shopt -o nounset | tr -d '[:blank:]')";
set +u;
for default_conda_env_name in ${DEFAULT_CONDA_ENV:-} ${CONDA_DEFAULT_ENV:-} base; do
    if [ -z "${default_conda_env_name:-}" ]; then continue; fi
    if grep -qF "(${default_conda_env_name})" <<< "${CONDA_PROMPT_MODIFIER:-}"; then break; fi
    if conda activate "${default_conda_env_name}" 2>/dev/null; then break; else continue; fi
done
if test "nounseton" = "${nounseton}"; then set -u; fi;
unset nounseton;

if [ -n "${CONDA_EXE:-}" ]; then
    conda_bin_paths="$(dirname "$(dirname "${CONDA_EXE}")")/condabin";
    if test -n "${CONDA_PREFIX:+x}"; then
        conda_bin_paths="${conda_bin_paths} ${CONDA_PREFIX}/bin";
    fi
    for conda_bin_path in ${conda_bin_paths}; do
        if [ -n "${PATH##*"$conda_bin_path"*}" ]; then
            export PATH="$conda_bin_path:$PATH";
        fi
    done
    if [ -n "${PATH##*"/opt/conda/bin"*}" ]; then
        export PATH="$PATH:/opt/conda/bin";
    fi
    unset conda_bin_paths;
fi
