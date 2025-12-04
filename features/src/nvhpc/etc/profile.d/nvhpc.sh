if ! command -V module 2>&1 | grep -q function; then
    . /etc/profile.d/lmod._sh;
fi

if [ -n "${PATH##*"${NVHPC_ROOT}/compilers/bin"*}" ]; then
    for NVHPC_MODULEFILES_DIR in "${NVHPC_MODULEFILE_DIRS[@]}"; do
        if [ -n "${MODULEPATH##*"${NVHPC_MODULEFILES_DIR}"*}" ]; then
            module use -a "${NVHPC_MODULEFILES_DIR}";
        fi
    done
    unset NVHPC_MODULEFILES_DIR;
    for NVHPC_MODULE_NAME in "nvhpc-hpcx/${NVHPC_VERSION}"; do
        if ! module list "${NVHPC_MODULE_NAME}" 2>&1 | grep -q 'None found.'; then
            if ! module list 2>&1 | grep -q "${NVHPC_MODULE_NAME}"; then
                module try-load "${NVHPC_MODULE_NAME}" >/dev/null 2>&1;
            fi
        fi
    done
    unset NVHPC_MODULE_NAME;

    # Have to source and manually call hpcx_load for nvhpc>=25.7
    if [ "${NVHPC_VERSION_MAJOR}" -ge 25 ] \
    && [ "${NVHPC_VERSION_MINOR}" -ge 7 ]; then
        HPCX_INIT="$(find -L "$NVHPC_ROOT"/comm_libs/ -path '*/latest/hpcx-init.sh' -print -quit)";
        if [ -n "${HPCX_INIT:+x}" ] && [ -s "${HPCX_INIT}" ]; then
            . "$HPCX_INIT";
            hpcx_load;
        fi
        unset HPCX_INIT;
    fi
fi
