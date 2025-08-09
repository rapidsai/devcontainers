if ! command -v module 2>&1 | grep -q function; then
    . /etc/profile.d/lmod._sh;
fi

if [ -n "${PATH##*"${NVHPC_ROOT}/compilers/bin"*}" ]; then
    for NVHPC_MODULEFILES_DIR in "${NVHPC_MODULEFILE_DIRS[@]}"; do
        if [ -n "${MODULEPATH##*"${NVHPC_MODULEFILES_DIR}"*}" ]; then
            module use -a "${NVHPC_MODULEFILES_DIR}";
        fi
    done
    unset NVHPC_MODULEFILES_DIR
    for NVHPC_MODULE_NAME in "nvhpc-hpcx/${NVHPC_VERSION}"; do
        if ! module list "${NVHPC_MODULE_NAME}" 2>&1 | grep -q 'None found.'; then
            if ! module list 2>&1 | grep -q "${NVHPC_MODULE_NAME}"; then
                module try-load "${NVHPC_MODULE_NAME}" >/dev/null 2>&1;
            fi
        fi
    done
    unset NVHPC_MODULE_NAME;
fi
