__nvarch="${NVARCH:-${NVARCH}}";
__cuda_home="${CUDA_HOME:-${CUDA_HOME}}";
__cuda_path="${CUDA_PATH:-${CUDA_HOME}}";
__cuda_version="${CUDA_VERSION:-${CUDA_VERSION}}";
__cuda_version_major="${CUDA_VERSION_MAJOR:-${CUDA_VERSION_MAJOR}}";
__cuda_version_minor="${CUDA_VERSION_MINOR:-${CUDA_VERSION_MINOR}}";
__cuda_version_patch="${CUDA_VERSION_PATCH:-${CUDA_VERSION_PATCH}}";

export NVARCH="${__nvarch}";
export CUDA_HOME="${__cuda_home}";
export CUDA_PATH="${__cuda_path}";
export CUDA_VERSION="${__cuda_version}";
export CUDA_VERSION_MAJOR="${__cuda_version_major}";
export CUDA_VERSION_MINOR="${__cuda_version_minor}";
export CUDA_VERSION_PATCH="${__cuda_version_patch}";

if [ -n "${PATH##*"/usr/local/nvidia/bin:${_cuda_home}/bin"*}" ]; then
    export PATH="/usr/local/nvidia/bin:${_cuda_home}/bin:${PATH}";
fi

if [ -z "${LIBRARY_PATH:-}" ] \
|| [ -n "${LIBRARY_PATH##*"${_cuda_home}/lib64/stubs"*}" ]; then
    export LIBRARY_PATH="${_cuda_home}/lib64/stubs${LIBRARY_PATH:+:$LIBRARY_PATH}"
fi

if [ -z "${LD_LIBRARY_PATH:-}" ] \
|| [ -n "${LD_LIBRARY_PATH##*"/usr/local/nvidia/lib:/usr/local/nvidia/lib64"*}" ]; then
    export LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

unset __nvarch __cuda_home __cuda_path __cuda_version __cuda_version_major __cuda_version_minor __cuda_version_patch
