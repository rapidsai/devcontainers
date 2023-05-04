if ! type module 2>&1 | grep -q function; then
    . /etc/profile.d/lmod._sh;
fi

if [ -n "${PATH##*"${NVHPC_ROOT}/compilers/bin"*}" ]; then
    module use "${NVHPC}/modulefiles";
    module use "${NVHPC_ROOT}/comm_libs/hpcx/latest/modulefiles";
    module try-load "nvhpc-nompi/${NVHPC_VERSION}" >/dev/null 2>&1;
    module try-load "nvhpc-nompi" >/dev/null 2>&1;
    module try-load "hpcx-mt" >/dev/null 2>&1;
    module try-load "hpcx" >/dev/null 2>&1;
fi
