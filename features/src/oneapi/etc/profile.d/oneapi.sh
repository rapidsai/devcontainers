if ! command -V module 2>&1 | grep -q function; then
    . /etc/profile.d/lmod._sh;
fi

if [ -n "${PATH##*"/opt/intel/oneapi/compiler/${ICC_VERSION}/linux/bin"*}" ]; then
    if test -f /opt/intel/oneapi/setvars.sh; then
        . /opt/intel/oneapi/setvars.sh --force >/dev/null 2>&1;
    else
        module use "/opt/intel/oneapi/compiler/${ICC_VERSION}/modulefiles";
        module use "/opt/intel/oneapi/compiler/${ICC_VERSION}/linux/lib/oclfpga/modulefiles";
        module try-load "compiler" >/dev/null 2>&1;
        module try-load "icc" >/dev/null 2>&1;
    fi
fi
