if ! command -v module 2>&1 | grep -q function; then
    . /etc/profile.d/lmod._sh;
fi

if [ -n "${PATH##*"${NVHPC_ROOT}/compilers/bin"*}" ]; then
    export PATH="${NVHPC_ROOT}/compilers/bin:$PATH";
fi
