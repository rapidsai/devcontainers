export LIT_VERSION="${LIT_VERSION}";
export DOXYGEN_VERSION="${DOXYGEN_VERSION}";

if  [ -f "${USERHOME}/.local/share/venvs/cccl/bin/activate" ] \
 && [ -z "${VIRTUAL_ENV:-}" -o "${VIRTUAL_ENV}" != "${USERHOME}/.local/share/venvs/cccl" ]; then
    . "${USERHOME}/.local/share/venvs/cccl/bin/activate";
elif [ -n "${VIRTUAL_ENV_PROMPT:-}" ]; then
    if ! echo "${PS1:-}" | grep -qF "${VIRTUAL_ENV_PROMPT}"; then
        export PS1="${VIRTUAL_ENV_PROMPT}${PS1:-}";
    fi
fi
