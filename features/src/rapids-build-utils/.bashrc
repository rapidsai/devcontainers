export CONDA_ALWAYS_YES=true;

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
