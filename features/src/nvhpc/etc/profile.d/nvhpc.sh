. /etc/profile.d/lmod._sh

if [ -n "${PATH##*"${NVHPC_ROOT}/compilers/bin"*}" ]; then
    module use "${NVHPC}/modulefiles";
    module use "${NVHPC_ROOT}/comm_libs/hpcx/latest/modulefiles";
    module try-load "nvhpc-nompi/${NVHPC_VERSION}";
    module try-load "nvhpc-nompi";
    module try-load "hpcx-mt";
    module try-load "hpcx";
fi
