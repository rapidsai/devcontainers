DEVCONTAINERS_NVHPC_LOADED_BY="${DEVCONTAINERS_NVHPC_LOADED_BY:-}"

if ! test "${DEVCONTAINERS_NVHPC_LOADED_BY:-}" = "$(whoami)"; then

    # "unload" lmod so all the modules are loaded from scratch
    for __module_unload_func_name in clearMT clearLmod; do
        if ! command -V $__module_unload_func_name 2>&1 | grep -q function; then
            . /etc/profile.d/lmod._sh
        fi
        $__module_unload_func_name >/dev/null 2>&1
    done
    unset __module_unload_func_name

    if ! command -V module 2>&1 | grep -q function; then
        . /etc/profile.d/lmod._sh;
    fi

    # Restore MODULEPATH since it is cleared by `clearLmod`
    for NVHPC_MODULEFILES_DIR in "${NVHPC_MODULEFILE_DIRS[@]}"; do
        if [ -n "${MODULEPATH##*"${NVHPC_MODULEFILES_DIR}"*}" ]; then
            module use -a "${NVHPC_MODULEFILES_DIR}";
        fi
    done
    unset NVHPC_MODULEFILES_DIR;

    # Load the NHVPC modules again
    for NVHPC_MODULE_NAME in "nvhpc-hpcx-cuda${NVHPC_CUDA_VERSION_MAJOR}/${NVHPC_VERSION}" \
                             "nvhpc-hpcx/${NVHPC_VERSION}"; do
        if ! module list "${NVHPC_MODULE_NAME}" 2>&1 | grep -q 'None found.'; then
            if ! module list 2>&1 | grep -q "${NVHPC_MODULE_NAME}"; then
                module try-load "${NVHPC_MODULE_NAME}" >/dev/null 2>&1;
            fi
        fi
    done
    unset NVHPC_MODULE_NAME;

    # Have to source and manually call hpcx_load for nvhpc>=25.7
    HPCX_INIT="$(find -L "$NVHPC_ROOT"/comm_libs/ -path '*/latest/hpcx-init.sh' -print -quit)";
    if [ -n "${HPCX_INIT:+x}" ] && [ -s "${HPCX_INIT}" ]; then
        . "$HPCX_INIT";
        hpcx_load;
    fi
    unset HPCX_INIT;

    DEVCONTAINERS_NVHPC_LOADED_BY="$(whoami)"
fi

export DEVCONTAINERS_NVHPC_LOADED_BY
