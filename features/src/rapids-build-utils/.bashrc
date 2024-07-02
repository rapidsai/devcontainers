export CONDA_ALWAYS_YES="true";
export CC="${CC:-"/usr/bin/gcc"}";
export CXX="${CXX:-"/usr/bin/g++"}";
export CUDAHOSTCXX="${CXX}";
export CUDAARCHS="${CUDAARCHS:-all-major}";
export CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}";
export CMAKE_EXPORT_COMPILE_COMMANDS="${CMAKE_EXPORT_COMPILE_COMMANDS:-ON}";

if [[ "${PYTHON_PACKAGE_MANAGER:-}" == "pip" ]]; then
    if  [ -n "${DEFAULT_VIRTUAL_ENV:-}" ] \
     && [ -f ~/".local/share/venvs/${DEFAULT_VIRTUAL_ENV}/bin/activate" ] \
     && [ -z "${VIRTUAL_ENV:-}" -o "${VIRTUAL_ENV}" != ~/".local/share/venvs/${DEFAULT_VIRTUAL_ENV}" ]; then
        . ~/".local/share/venvs/${DEFAULT_VIRTUAL_ENV}/bin/activate";
    elif [ -n "${VIRTUAL_ENV_PROMPT:-}" ]; then
        if ! echo "${PS1:-}" | grep -qF "${VIRTUAL_ENV_PROMPT}"; then
            export PS1="${VIRTUAL_ENV_PROMPT}${PS1:-}";
        fi
    fi
fi

# shellcheck disable=SC2155
export CUDA_VERSION_MAJOR_MINOR="$(grep -Po '^[0-9]+\.[0-9]+' <<< "${CUDA_VERSION:-${CUDA_VERSION_MAJOR:-12}.${CUDA_VERSION_MINOR:-0}}")";
